part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {
  const LoadTasks();
}

class LoadTaskById extends TaskEvent {
  final String taskId;
  const LoadTaskById(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class AddTask extends TaskEvent {
  final Task task;
  const AddTask(this.task);
  @override
  List<Object?> get props => [task];
}

class UpdateTask extends TaskEvent {
  final Task task;
  const UpdateTask(this.task);
  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TaskEvent {
  final String taskId;
  const DeleteTask(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class ToggleTaskCompletion extends TaskEvent {
  final Task task;
  const ToggleTaskCompletion(this.task);
  @override
  List<Object?> get props => [task];
}

class SearchTasks extends TaskEvent {
  final String query;
  const SearchTasks(this.query);
  @override
  List<Object?> get props => [query];
}

class ApplyTaskSort extends TaskEvent {
  final TaskSortOption sortOption;
  const ApplyTaskSort(this.sortOption);
  @override
  List<Object?> get props => [sortOption];
}

class ApplyTaskFilter extends TaskEvent {
  final TaskFilterOption filterOption;
  const ApplyTaskFilter(this.filterOption);
  @override
  List<Object?> get props => [filterOption];
}

class ApplyTagFilter extends TaskEvent {
  final String? tag;
  const ApplyTagFilter(this.tag);
  @override
  List<Object?> get props => [tag];
}

class SelectTaskForDetail extends TaskEvent {
  final String? taskId;
  const SelectTaskForDetail(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class ShowAddTaskFormInDetail extends TaskEvent {}

class ClearDetailPane extends TaskEvent {}