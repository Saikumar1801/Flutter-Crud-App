import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

// Centralized imports
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
import 'task_filter_sort_values.dart';
// NO DataTransferService import

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;
  // NO DataTransferService dependency

  List<Task> _allTasksMasterList = [];
  String _currentSearchQuery = "";
  String? _currentTagFilter;
  TaskSortOption _currentSortOption = TaskSortOption.createdDateDesc;
  TaskFilterOption _currentFilterOption = TaskFilterOption.all;
  String? _selectedTaskIdForDetailInternal;
  DetailPaneMode _detailPaneModeInternal = DetailPaneMode.none;

  String get currentSearchQuery => _currentSearchQuery;
  TaskSortOption get currentSortOptionFromBloc => _currentSortOption;
  TaskFilterOption get currentFilterOptionFromBloc => _currentFilterOption;
  String? get currentTagFilterFromBloc => _currentTagFilter;
  List<Task> get allTasksMasterList => List.unmodifiable(_allTasksMasterList);

  TaskBloc({
    required this.taskRepository,
    // NO DataTransferService injection
  }) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<LoadTaskById>(_onLoadTaskById);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<ToggleTaskCompletion>(_onToggleTaskCompletion);
    on<SearchTasks>(_onSearchTasks, transformer: (events, mapper) => events.debounceTime(const Duration(milliseconds: 400)).switchMap(mapper));
    on<ApplyTaskSort>(_onApplyTaskSort);
    on<ApplyTaskFilter>(_onApplyTaskFilter);
    on<ApplyTagFilter>(_onApplyTagFilter);
    on<SelectTaskForDetail>(_onSelectTaskForDetail);
    on<ShowAddTaskFormInDetail>(_onShowAddTaskFormInDetail);
    on<ClearDetailPane>(_onClearDetailPane);
    // NO Export/Import event handlers
  }

  @override
  void onTransition(Transition<TaskEvent, TaskState> transition) {
    super.onTransition(transition);
    appLogger.d('TaskBloc Transition: ${transition.currentState.runtimeType} -> ${transition.nextState.runtimeType} on ${transition.event.runtimeType}');
    if (transition.nextState is TasksLoaded) {
      final next = transition.nextState as TasksLoaded;
      appLogger.d('  TasksLoaded details: count=${next.tasks.length}, selectedId=${next.selectedTaskIdForDetail}, mode=${next.detailPaneMode}');
    }
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    appLogger.i("TaskBloc: Received LoadTasks event.");
    final currentState = state;
    if (currentState is TasksLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    } else {
      emit(TaskLoading());
    }

    final failureOrTasks = await taskRepository.getTasks();
    failureOrTasks.fold(
      (failure) {
        appLogger.w("TaskBloc: Error loading tasks - ${failure.message}");
        emit(TaskError(_mapFailureToMessage(failure)));
      },
      (tasks) {
        appLogger.d("TaskBloc: Tasks loaded with ${tasks.length} tasks.");
        _allTasksMasterList = List.from(tasks);
        _emitFilteredAndSortedTasks(emit, isRefreshing: false);
      },
    );
  }

  void _emitFilteredAndSortedTasks(Emitter<TaskState> emit, {bool isRefreshing = false}) {
    List<Task> tasksToProcess = List.from(_allTasksMasterList);

    if (_currentSearchQuery.isNotEmpty) {
      final lowerCaseQuery = _currentSearchQuery.toLowerCase();
      tasksToProcess = tasksToProcess.where((task) {
        return task.title.toLowerCase().contains(lowerCaseQuery) ||
               task.description.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    if (_currentFilterOption == TaskFilterOption.completed) {
      tasksToProcess = tasksToProcess.where((task) => task.isCompleted).toList();
    } else if (_currentFilterOption == TaskFilterOption.incomplete) {
      tasksToProcess = tasksToProcess.where((task) => !task.isCompleted).toList();
    }

    if (_currentTagFilter != null && _currentTagFilter!.isNotEmpty) {
      final tagToFilter = _currentTagFilter!.toLowerCase();
      tasksToProcess = tasksToProcess.where((task) {
        return task.tagList.any((tag) => tag.toLowerCase() == tagToFilter);
      }).toList();
    }

    if (_selectedTaskIdForDetailInternal != null &&
        !tasksToProcess.any((task) => task.id == _selectedTaskIdForDetailInternal)) {
      appLogger.i("Selected task $_selectedTaskIdForDetailInternal no longer in filtered list. Clearing detail pane.");
      _selectedTaskIdForDetailInternal = null;
      _detailPaneModeInternal = DetailPaneMode.none;
    }
    
    tasksToProcess.sort((a, b) {
      int comparisonResult = 0;
      switch (_currentSortOption) {
        case TaskSortOption.priorityAsc: comparisonResult = a.priority.index.compareTo(b.priority.index); break;
        case TaskSortOption.priorityDesc: comparisonResult = b.priority.index.compareTo(a.priority.index); break;
        case TaskSortOption.createdDateAsc: comparisonResult = a.createdDate.compareTo(b.createdDate); break;
        case TaskSortOption.createdDateDesc: comparisonResult = b.createdDate.compareTo(a.createdDate); break;
        case TaskSortOption.titleAsc: comparisonResult = a.title.toLowerCase().compareTo(b.title.toLowerCase()); break;
        case TaskSortOption.titleDesc: comparisonResult = b.title.toLowerCase().compareTo(a.title.toLowerCase()); break;
        case TaskSortOption.none: default: comparisonResult = 0; break;
      }
      return comparisonResult;
    });
    
    emit(TasksLoaded(
      tasksToProcess,
      isRefreshing: isRefreshing,
      currentSortOption: _currentSortOption,
      currentFilterOption: _currentFilterOption,
      currentTagFilter: _currentTagFilter,
      selectedTaskIdForDetail: _selectedTaskIdForDetailInternal,
      detailPaneMode: _detailPaneModeInternal,
    ));
  }

  void _onSearchTasks(SearchTasks event, Emitter<TaskState> emit) {
    _currentSearchQuery = event.query.trim();
    _emitFilteredAndSortedTasks(emit);
  }

  void _onApplyTaskSort(ApplyTaskSort event, Emitter<TaskState> emit) {
    _currentSortOption = event.sortOption;
    _emitFilteredAndSortedTasks(emit);
  }

  void _onApplyTaskFilter(ApplyTaskFilter event, Emitter<TaskState> emit) {
    _currentFilterOption = event.filterOption;
    _emitFilteredAndSortedTasks(emit);
  }

  void _onApplyTagFilter(ApplyTagFilter event, Emitter<TaskState> emit) {
    _currentTagFilter = event.tag;
    _emitFilteredAndSortedTasks(emit);
  }
  
  void _onSelectTaskForDetail(SelectTaskForDetail event, Emitter<TaskState> emit) {
    if (event.taskId == null) {
      _selectedTaskIdForDetailInternal = null;
      _detailPaneModeInternal = DetailPaneMode.none;
    } else {
      final taskExists = _allTasksMasterList.any((task) => task.id == event.taskId);
      if (taskExists) {
        _selectedTaskIdForDetailInternal = event.taskId;
        _detailPaneModeInternal = DetailPaneMode.viewOrEditTask;
      } else {
        _selectedTaskIdForDetailInternal = null;
        _detailPaneModeInternal = DetailPaneMode.none;
      }
    }
    if (state is TasksLoaded) {
      emit((state as TasksLoaded).copyWith(
        selectedTaskIdForDetail: _selectedTaskIdForDetailInternal,
        detailPaneMode: _detailPaneModeInternal,
        clearSelectedTask: event.taskId == null 
      ));
    }
  }

  void _onShowAddTaskFormInDetail(ShowAddTaskFormInDetail event, Emitter<TaskState> emit) {
    _selectedTaskIdForDetailInternal = null;
    _detailPaneModeInternal = DetailPaneMode.addTask;
    if (state is TasksLoaded) {
      emit((state as TasksLoaded).copyWith(clearSelectedTask: true, detailPaneMode: _detailPaneModeInternal));
    } else {
      emit(TasksLoaded(const [], detailPaneMode: DetailPaneMode.addTask));
    }
  }
  
  void _onClearDetailPane(ClearDetailPane event, Emitter<TaskState> emit) {
    _selectedTaskIdForDetailInternal = null;
    _detailPaneModeInternal = DetailPaneMode.none;
    if (state is TasksLoaded) {
      emit((state as TasksLoaded).copyWith(clearSelectedTask: true, detailPaneMode: _detailPaneModeInternal));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    final failureOrSuccess = await taskRepository.addTask(event.task);
    failureOrSuccess.fold(
      (failure) => emit(TaskError(_mapFailureToMessage(failure))),
      (addedTask) {
        emit(TaskMutationSuccess('Task "${addedTask.title}" added successfully.'));
        if (_detailPaneModeInternal == DetailPaneMode.addTask) {
          _selectedTaskIdForDetailInternal = addedTask.id;
          _detailPaneModeInternal = DetailPaneMode.viewOrEditTask;
        }
        add(const LoadTasks());
      },
    );
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    final failureOrSuccess = await taskRepository.updateTask(event.task);
    failureOrSuccess.fold(
      (failure) => emit(TaskError(_mapFailureToMessage(failure))),
      (updatedTask) {
        emit(TaskMutationSuccess('Task "${updatedTask.title}" updated successfully.'));
        add(const LoadTasks());
      },
    );
  }
  
  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    final String deletedTaskId = event.taskId;
    final failureOrSuccess = await taskRepository.deleteTask(deletedTaskId);
    failureOrSuccess.fold(
      (failure) => emit(TaskError(_mapFailureToMessage(failure))),
      (_) {
        emit(const TaskMutationSuccess('Task deleted successfully.'));
        if (_selectedTaskIdForDetailInternal == deletedTaskId) {
          _selectedTaskIdForDetailInternal = null;
          _detailPaneModeInternal = DetailPaneMode.none;
        }
        add(const LoadTasks());
      },
    );
  }
  
  Future<void> _onToggleTaskCompletion(ToggleTaskCompletion event, Emitter<TaskState> emit) async {
    final updatedTask = event.task.copyWith(isCompleted: !event.task.isCompleted);
    final failureOrSuccess = await taskRepository.updateTask(updatedTask);
    failureOrSuccess.fold(
      (failure) => emit(TaskError(_mapFailureToMessage(failure))),
      (returnedTask) {
        final indexInAllTasks = _allTasksMasterList.indexWhere((t) => t.id == returnedTask.id);
        if (indexInAllTasks != -1) {
          _allTasksMasterList[indexInAllTasks] = returnedTask;
        } else {
          add(const LoadTasks()); return;
        }
        _emitFilteredAndSortedTasks(emit);
      },
    );
  }

   Future<void> _onLoadTaskById(LoadTaskById event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    final failureOrTask = await taskRepository.getTaskById(event.taskId);
    failureOrTask.fold(
      (failure) => emit(TaskError(_mapFailureToMessage(failure))),
      (task) => emit(TaskDetailLoaded(task)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure: return 'Server Error: ${failure.message}';
      case CacheFailure: return 'Cache Error: ${failure.message}';
      case NetworkFailure: return 'Network Error: ${failure.message}. Please check your connection.';
      // Remove failure types that were specific to DataTransferService if they are not defined elsewhere
      // case PermissionFailure: return 'Permission Error: ${failure.message}';
      // case GenericFailure: return 'Operation Failed: ${failure.message}';
      default: return 'An unexpected error occurred: ${failure.message}';
    }
  }
}