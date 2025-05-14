import 'package:bloc_test/bloc_test.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_crud_app/core/errors/failures.dart';
import 'package:flutter_crud_app/data/models/task_model.dart';
import 'package:flutter_crud_app/data/repositories/task_repository.dart';
import 'package:flutter_crud_app/presentation/bloc/task_bloc/task_bloc.dart';
import 'package:flutter_crud_app/presentation/bloc/task_bloc/task_filter_sort_values.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}
class FakeTask extends Fake implements Task {}
class FakeTaskEvent extends Fake implements TaskEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTask());
    registerFallbackValue(FakeTaskEvent());
  });

  late TaskBloc taskBloc;
  late MockTaskRepository mockTaskRepository;

  final tTask1 = Task(id: '1', title: 'Task Alpha', createdDate: DateTime(2023, 1, 1), priority: TaskPriority.low, isCompleted: false, tags: "work");
  final tTask2 = Task(id: '2', title: 'Task Beta', createdDate: DateTime(2023, 1, 2), priority: TaskPriority.high, isCompleted: true, tags: "home,urgent");
  final tTask3 = Task(id: '3', title: 'Task Gamma', createdDate: DateTime(2023, 1, 3), priority: TaskPriority.medium, isCompleted: false, tags: "work,errand");

  final tTaskListUnsorted = [tTask1, tTask2, tTask3];
  final tTaskListDefaultSorted = [tTask3, tTask2, tTask1];

  setUp(() {
    mockTaskRepository = MockTaskRepository();
    taskBloc = TaskBloc(taskRepository: mockTaskRepository);
  });

  tearDown(() {
    taskBloc.close();
  });

  test('initial state should be TaskInitial', () {
    expect(taskBloc.state, TaskInitial());
  });

  group('LoadTasks Event', () {
    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoading, TasksLoaded with default sort] when getTasks is successful',
      build: () {
        when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right(tTaskListUnsorted));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const LoadTasks()),
      expect: () => [
        TaskLoading(),
        TasksLoaded(tTaskListDefaultSorted, currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoading, TaskError] when getTasks fails',
      build: () {
        when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => const Left(ServerFailure('Server Error')));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const LoadTasks()),
      expect: () => [ TaskLoading(), const TaskError('Server Error: Server Error'), ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits [TasksLoaded(isRefreshing: true), TasksLoaded(isRefreshing: false, default sort)] during refresh',
      build: () {
        when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right(tTaskListUnsorted));
        return taskBloc;
      },
      seed: () => const TasksLoaded([], currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all),
      act: (bloc) => bloc.add(const LoadTasks()),
      expect: () => [
        const TasksLoaded([], isRefreshing: true, currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all),
        TasksLoaded(tTaskListDefaultSorted, isRefreshing: false, currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all),
      ],
    );
  });

  group('AddTask Event', () {
    final tNewTask = Task(title: 'New Task Zero', createdDate: DateTime(2023, 1, 4)); // Newest
    final tAddedTaskFromServer = tNewTask.copyWith(id: 'server_id_new');
    final tExpectedListAfterAdd = [tAddedTaskFromServer, ...tTaskListDefaultSorted];

    blocTest<TaskBloc, TaskState>(
      'emits [TaskMutationSuccess, TaskLoading, TasksLoaded with new task sorted] after successful AddTask',
      build: () {
        when(() => mockTaskRepository.addTask(any<Task>())).thenAnswer((_) async => Right(tAddedTaskFromServer));
        when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right([tAddedTaskFromServer, ...tTaskListUnsorted]));
        return taskBloc;
      },
      act: (bloc) => bloc.add(AddTask(tNewTask)),
      expect: () => [
        TaskMutationSuccess('Task "New Task Zero" added successfully.'),
        TaskLoading(),
        TasksLoaded(tExpectedListAfterAdd, currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all),
      ],
    );
  });

  group('SearchTasks Event', () {
    final taskS0 = Task(id: 's0', title: 'Search Alpha One', createdDate: DateTime(2023,3,3));
    final taskS1 = Task(id: 's1', title: 'Search Beta Task', createdDate: DateTime(2023,3,2));
    final taskS2 = Task(id: 's2', title: 'Another Item Alpha Two', createdDate: DateTime(2023,3,1));
    final searchTasksListUnsorted = [taskS0, taskS1, taskS2];
    // Default sort by createdDateDesc: [taskS0, taskS1, taskS2]
    final searchTasksListDefaultSorted = [taskS0, taskS1, taskS2];

    blocTest<TaskBloc, TaskState>(
      'emits [TasksLoaded] with filtered tasks (title search) based on query',
      build: () {
        when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right(searchTasksListUnsorted));
        return taskBloc;
      },
      act: (bloc) async {
        bloc.add(const LoadTasks());
        await Future.delayed(const Duration(milliseconds: 50)); 
        bloc.add(const SearchTasks('Alpha'));
      },
      wait: const Duration(milliseconds: 500), 
      expect: () => [
        TaskLoading(),
        TasksLoaded(searchTasksListDefaultSorted, currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all),
        // After searching "Alpha", default sort applies to filtered: [taskS0, taskS2]
        TasksLoaded([taskS0, taskS2], currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'clears search and shows all tasks when SearchTasks event has empty query',
      build: () {
        when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right(searchTasksListUnsorted));
        return taskBloc;
      },
      act: (bloc) async {
        bloc.add(const LoadTasks()); // Emits Loading, then TasksLoaded(all)
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const SearchTasks('Beta')); // Emits TasksLoaded(filtered for Beta) after debounce
        await Future.delayed(const Duration(milliseconds: 500)); 
        bloc.add(const SearchTasks(''));    // Emits TasksLoaded(all) after debounce
      },
      wait: const Duration(milliseconds: 500), // Wait for the final SearchTasks('') debounce
      skip: 2, // Skip TaskLoading and the first TasksLoaded (all tasks from initial LoadTasks)
      expect: () => [
        // After SearchTasks('Beta')
        TasksLoaded([taskS1], currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all),
        // After SearchTasks('')
        TasksLoaded(searchTasksListDefaultSorted, currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all),
      ],
    );
  });

  group('ApplyTaskFilter, ApplyTaskSort, ApplyTagFilter Events', () {
    // These tasks will be returned by mockTaskRepository.getTasks() for this group
    final taskX = Task(id: 'x', title: 'Xylophone', createdDate: DateTime(2023,1,5), isCompleted: false, tags: "music,hobby", priority: TaskPriority.low);
    final taskY = Task(id: 'y', title: 'Yoga', createdDate: DateTime(2023,1,4), isCompleted: false, tags: "health,hobby", priority: TaskPriority.medium);
    final taskZ = Task(id: 'z', title: 'Zebra Watching', createdDate: DateTime(2023,1,3), isCompleted: true, tags: "hobby,nature", priority: TaskPriority.high);
    final specificListUnsorted = [taskX, taskY, taskZ];
    // Default sort by createdDateDesc: [taskX, taskY, taskZ] because X is newest.
    final specificListDefaultSorted = [taskX, taskY, taskZ];


    blocTest<TaskBloc, TaskState>(
      'filters by completed, then by tag "hobby", then sorts by title ascending',
      build: () {
        // Stub getTasks for *this test instance* of the BLoC
        when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right(specificListUnsorted));
        return taskBloc; // taskBloc is created fresh in its own setUp
      },
      act: (bloc) async {
        bloc.add(const LoadTasks()); // Emits Loading, then TasksLoaded(specificListDefaultSorted)
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(const ApplyTaskFilter(TaskFilterOption.incomplete)); // Filters to [taskX, taskY] (order preserved by dateDesc)
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(const ApplyTagFilter("hobby")); // Still [taskX, taskY] (both have "hobby", order by dateDesc)
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(const ApplyTaskSort(TaskSortOption.titleAsc)); // Sorts [taskX, taskY] by title -> [taskX, taskY]
      },
      skip: 2, // Skip TaskLoading and initial TasksLoaded from LoadTasks
      expect: () {
        // 1. After ApplyTaskFilter(TaskFilterOption.incomplete)
        //    Input to filter: [taskX, taskY, taskZ] (default sorted)
        //    Output: [taskX, taskY] (sorted by dateDesc)
        final state1 = TasksLoaded([taskX, taskY], currentFilterOption: TaskFilterOption.incomplete, currentSortOption: TaskSortOption.createdDateDesc, currentTagFilter: null);
        
        // 2. After ApplyTagFilter("hobby")
        //    Input to filter: [taskX, taskY]
        //    Output: [taskX, taskY] (sorted by dateDesc)
        final state2 = TasksLoaded([taskX, taskY], currentFilterOption: TaskFilterOption.incomplete, currentSortOption: TaskSortOption.createdDateDesc, currentTagFilter: "hobby");
        
        // 3. After ApplyTaskSort(TaskSortOption.titleAsc)
        //    Input to sort: [taskX, taskY]
        //    Output: [taskX, taskY] (Xylophone, Yoga - already sorted by title relative to each other from date sort)
        final state3 = TasksLoaded([taskX, taskY], currentFilterOption: TaskFilterOption.incomplete, currentSortOption: TaskSortOption.titleAsc, currentTagFilter: "hobby");
        
        return [state1, state2, state3];
      },
    );

    blocTest<TaskBloc, TaskState>(
      'clears tag filter when ApplyTagFilter(null) is called',
      build: () {
        when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right(tTaskListUnsorted));
        return taskBloc;
      },
      act: (bloc) async {
        bloc.add(const LoadTasks());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const ApplyTagFilter("work")); 
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const ApplyTagFilter(null));  
      },
      skip: 2,
      expect: () => [
        TasksLoaded([tTask3, tTask1], currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all, currentTagFilter: "work"),
        TasksLoaded(tTaskListDefaultSorted, currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all, currentTagFilter: null),
      ],
    );
  });

  group('ToggleTaskCompletion Event', () {
    blocTest<TaskBloc, TaskState>(
      'updates task completion and re-applies filters/sorts correctly',
      build: () {
        when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right(tTaskListUnsorted));
        final tTask1Toggled = tTask1.copyWith(isCompleted: true);
        when(() => mockTaskRepository.updateTask(any<Task>(that: predicate((arg) {
              final task = arg as Task;
              return task.id == tTask1.id && task.isCompleted == !tTask1.isCompleted;
            }))))
            .thenAnswer((_) async => Right(tTask1Toggled));
        return taskBloc;
      },
      act: (bloc) async {
        bloc.add(const LoadTasks());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const ApplyTaskFilter(TaskFilterOption.incomplete));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(ToggleTaskCompletion(tTask1)); 
      },
      skip: 2, 
      expect: () {
        return [
          TasksLoaded([tTask3, tTask1], currentFilterOption: TaskFilterOption.incomplete, currentSortOption: TaskSortOption.createdDateDesc),
          TasksLoaded([tTask3], currentFilterOption: TaskFilterOption.incomplete, currentSortOption: TaskSortOption.createdDateDesc),
        ];
      },
    );
  });

  group('DeleteTask Event and Detail Pane interaction', () {
    blocTest<TaskBloc, TaskState>(
      'clears detail pane selection if the deleted task was selected',
      build: () {
        when(() => mockTaskRepository.deleteTask(tTask2.id)).thenAnswer((_) async => const Right(null));
        // This getTasks will be called by LoadTasks *after* the delete.
        when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right([tTask1, tTask3]));
        return taskBloc;
      },
      seed: () => TasksLoaded(
        tTaskListDefaultSorted, 
        selectedTaskIdForDetail: tTask2.id,
        detailPaneMode: DetailPaneMode.viewOrEditTask,
        currentSortOption: TaskSortOption.createdDateDesc,
        currentFilterOption: TaskFilterOption.all
      ),
      act: (bloc) => bloc.add(DeleteTask(tTask2.id)),
      expect: () => [
        TaskMutationSuccess('Task deleted successfully.'),
        TaskLoading(),
        TasksLoaded([tTask3, tTask1], selectedTaskIdForDetail: null, detailPaneMode: DetailPaneMode.none, currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all),
      ],
    );
  });

  group('Detail Pane Events', () {
    blocTest<TaskBloc, TaskState>(
        'SelectTaskForDetail updates selectedTaskId and detailPaneMode',
        build: () {
          when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right(tTaskListUnsorted));
          return taskBloc;
        },
        act: (bloc) async {
          bloc.add(const LoadTasks());
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(SelectTaskForDetail(tTask1.id));
        },
        skip: 2,
        expect: () => [
          TasksLoaded(tTaskListDefaultSorted, selectedTaskIdForDetail: tTask1.id, detailPaneMode: DetailPaneMode.viewOrEditTask, currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all)
        ],
      );

      blocTest<TaskBloc, TaskState>(
        'ShowAddTaskFormInDetail sets detailPaneMode to addTask and clears selectedTaskId',
        build: () {
          when(() => mockTaskRepository.getTasks()).thenAnswer((_) async => Right(tTaskListUnsorted));
          return taskBloc;
        },
        act: (bloc) async {
          bloc.add(const LoadTasks());
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(SelectTaskForDetail(tTask1.id));
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(ShowAddTaskFormInDetail());
        },
        skip: 3,
        expect: () => [
          TasksLoaded(tTaskListDefaultSorted, selectedTaskIdForDetail: null, detailPaneMode: DetailPaneMode.addTask, currentSortOption: TaskSortOption.createdDateDesc, currentFilterOption: TaskFilterOption.all)
        ],
      );
  });
}