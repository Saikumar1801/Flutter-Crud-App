part of 'task_bloc.dart';


abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

enum DetailPaneMode { none, viewOrEditTask, addTask }

class TasksLoaded extends TaskState {
  final List<Task> tasks;
  final bool isRefreshing;
  final TaskSortOption currentSortOption;
  final TaskFilterOption currentFilterOption;
  final String? currentTagFilter;
  final String? selectedTaskIdForDetail;
  final DetailPaneMode detailPaneMode;

  const TasksLoaded(
    this.tasks, {
    this.isRefreshing = false,
    this.currentSortOption = TaskSortOption.createdDateDesc,
    this.currentFilterOption = TaskFilterOption.all,
    this.currentTagFilter,
    this.selectedTaskIdForDetail,
    this.detailPaneMode = DetailPaneMode.none,
  });

  @override
  List<Object?> get props => [
        tasks,
        isRefreshing,
        currentSortOption,
        currentFilterOption,
        currentTagFilter,
        selectedTaskIdForDetail,
        detailPaneMode,
      ];

  TasksLoaded copyWith({
    List<Task>? tasks,
    bool? isRefreshing,
    TaskSortOption? currentSortOption,
    TaskFilterOption? currentFilterOption,
    String? currentTagFilter,
    bool clearTagFilter = false,
    String? selectedTaskIdForDetail,
    bool clearSelectedTask = false,
    DetailPaneMode? detailPaneMode,
  }) {
    return TasksLoaded(
      tasks ?? this.tasks,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      currentSortOption: currentSortOption ?? this.currentSortOption,
      currentFilterOption: currentFilterOption ?? this.currentFilterOption,
      currentTagFilter: clearTagFilter ? null : (currentTagFilter ?? this.currentTagFilter),
      selectedTaskIdForDetail: clearSelectedTask ? null : (selectedTaskIdForDetail ?? this.selectedTaskIdForDetail),
      detailPaneMode: detailPaneMode ?? this.detailPaneMode,
    );
  }

  Task? getSelectedTaskFromMasterList(List<Task> masterList) {
    if (selectedTaskIdForDetail == null) return null;
    try {
      return masterList.firstWhere((task) => task.id == selectedTaskIdForDetail);
    } catch (e) {
      return null;
    }
  }
}

class TaskDetailLoaded extends TaskState {
  final Task task;
  const TaskDetailLoaded(this.task);
  @override
  List<Object?> get props => [task];
}

class TaskMutationSuccess extends TaskState {
  final String message;
  final List<Task>? updatedTasks;
  const TaskMutationSuccess(this.message, {this.updatedTasks});
  @override
  List<Object?> get props => [message, updatedTasks];
}

class TaskError extends TaskState {
  final String message;
  const TaskError(this.message);
  @override
  List<Object?> get props => [message];
}