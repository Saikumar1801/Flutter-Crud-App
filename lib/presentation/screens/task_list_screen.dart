import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task_bloc/task_bloc.dart';
import '../bloc/task_bloc/task_filter_sort_values.dart';
import '../theme_cubit/theme_cubit.dart';
import '../widgets/task_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/network_status_banner.dart';
import 'task_form_screen.dart';
import '../../data/models/task_model.dart';

const double kTabletBreakpoint = 720.0;

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _textFieldQuery = "";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_textFieldQuery != _searchController.text.trim()) {
        setState(() { _textFieldQuery = _searchController.text.trim(); });
      }
      context.read<TaskBloc>().add(SearchTasks(_searchController.text.trim()));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getSortOptionText(TaskSortOption option) {
    switch (option) {
      case TaskSortOption.priorityDesc: return 'Priority (High > Low)';
      case TaskSortOption.priorityAsc: return 'Priority (Low > High)';
      case TaskSortOption.createdDateDesc: return 'Date (Newest)';
      case TaskSortOption.createdDateAsc: return 'Date (Oldest)';
      case TaskSortOption.titleAsc: return 'Title (A-Z)';
      case TaskSortOption.titleDesc: return 'Title (Z-A)';
      case TaskSortOption.none: default: return 'Default Order';
    }
  }

  String _getFilterOptionText(TaskFilterOption option) {
    switch (option) {
      case TaskFilterOption.all: return 'All Tasks';
      case TaskFilterOption.completed: return 'Completed';
      case TaskFilterOption.incomplete: return 'Incomplete';
      default: return option.toString().split('.').last;
    }
  }

  void _showFeedbackMessage(String message, bool isError, {Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    final effectiveContext = _scaffoldKey.currentContext ?? context;
    final messenger = ScaffoldMessenger.of(effectiveContext);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError 
          ? Theme.of(effectiveContext).colorScheme.errorContainer 
          : Theme.of(effectiveContext).colorScheme.primaryContainer,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      action: SnackBarAction(label: 'Dismiss', onPressed: () => messenger.hideCurrentSnackBar()),
    ));
  }

  Widget _buildTaskListPane({
    required List<Task> tasks,
    required bool isWideScreen,
    required String? selectedTaskId,
    required TasksLoaded currentState,
  }) {
    if (tasks.isEmpty && !currentState.isRefreshing) {
      final taskBloc = context.read<TaskBloc>();
      final currentSearch = taskBloc.currentSearchQuery;
      final currentTag = taskBloc.currentTagFilterFromBloc;
      final currentCompletionFilter = taskBloc.currentFilterOptionFromBloc;
      String emptyMessage = 'No tasks yet!';
      String subMessage = 'Tap the + button below to add your first task.';
      if (currentSearch.isNotEmpty) { emptyMessage = 'No tasks found for "$currentSearch".'; subMessage = 'Try a different search or clear it.'; }
      else if (currentTag != null) { emptyMessage = 'No tasks found with tag "$currentTag".'; subMessage = 'Clear the tag filter or add tasks with this tag.'; }
      else if (currentCompletionFilter != TaskFilterOption.all) { emptyMessage = 'No ${currentCompletionFilter == TaskFilterOption.completed ? "completed" : "incomplete"} tasks found.'; subMessage = 'Try changing the completion filter.'; }
      else if (currentState.currentSortOption != TaskSortOption.createdDateDesc) { emptyMessage = 'No tasks match the current view.'; subMessage = 'Try adjusting filters or adding tasks.';}
      return Center(child: Padding( padding: const EdgeInsets.all(16.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.inbox_outlined, size: 60, color: Theme.of(context).hintColor), const SizedBox(height: 16), Text(emptyMessage, style: TextStyle(fontSize: 18, color: Theme.of(context).hintColor), textAlign: TextAlign.center), const SizedBox(height: 8), Text(subMessage, style: TextStyle(color: Theme.of(context).hintColor), textAlign: TextAlign.center), const SizedBox(height: 20), ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Refresh Tasks'),onPressed: () => context.read<TaskBloc>().add(const LoadTasks()))])));
    }
    return RefreshIndicator(onRefresh: () async { context.read<TaskBloc>().add(const LoadTasks()); await context.read<TaskBloc>().stream.firstWhere((s) => (s is TasksLoaded && !s.isRefreshing) || (s is TaskError)); }, child: ListView.builder(key: const PageStorageKey<String>('taskList'), padding: const EdgeInsets.only(bottom: 80), itemCount: tasks.length, itemBuilder: (context, index) { final task = tasks[index]; final bool isSelected = isWideScreen && task.id == selectedTaskId; return Material(color: isSelected ? Theme.of(context).highlightColor.withOpacity(0.2) : Colors.transparent, child: TaskCard(task: task, onTap: () { if (isWideScreen) { context.read<TaskBloc>().add(SelectTaskForDetail(task.id)); } else { Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlocProvider.value(value: BlocProvider.of<TaskBloc>(context), child: TaskFormScreen(task: task))));}}, onToggleComplete: () => context.read<TaskBloc>().add(ToggleTaskCompletion(task))));}));
  }

  Widget _buildDetailPaneScaffold(BuildContext context, TasksLoaded state) {
    final taskBloc = context.read<TaskBloc>();
    Widget detailContent; String appBarTitle = 'Task Details';
    Task? taskForForm = state.getSelectedTaskFromMasterList(taskBloc.allTasksMasterList);
    if (state.detailPaneMode == DetailPaneMode.addTask) { appBarTitle = 'Add New Task'; detailContent = TaskFormScreen(key: const ValueKey('add_task_form_detail_pane'));}
    else if (state.detailPaneMode == DetailPaneMode.viewOrEditTask && taskForForm != null) { appBarTitle = taskForForm.title.isEmpty ? 'Edit Task' : taskForForm.title; detailContent = TaskFormScreen(key: ValueKey(taskForForm.id), task: taskForForm);}
    else { return Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.article_outlined, size: 80, color: Theme.of(context).hintColor), const SizedBox(height: 20), Text('Select a task to view details', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).hintColor), textAlign: TextAlign.center), const SizedBox(height: 12), Text('Or create a new one.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).hintColor), textAlign: TextAlign.center), const SizedBox(height: 20), ElevatedButton.icon(icon: const Icon(Icons.add_circle_outline), label: const Text('Add New Task Here'), onPressed: () => taskBloc.add(ShowAddTaskFormInDetail()))]))); }
    return Scaffold(appBar: AppBar(title: Text(appBarTitle, overflow: TextOverflow.ellipsis), backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5), elevation: 1, automaticallyImplyLeading: false, actions: [ if (state.detailPaneMode != DetailPaneMode.none) IconButton(icon: const Icon(Icons.close), tooltip: "Close Detail", onPressed: () => taskBloc.add(ClearDetailPane()))]), body: BlocProvider.value(value: taskBloc, child: detailContent));
  }

  @override
  Widget build(BuildContext context) {
    final taskBlocState = context.watch<TaskBloc>().state;
    TaskSortOption currentSortForUI = TaskSortOption.createdDateDesc;
    TaskFilterOption currentFilterForUI = TaskFilterOption.all;
    String? currentTagFilterForUI;
    if (taskBlocState is TasksLoaded) { currentSortForUI = taskBlocState.currentSortOption; currentFilterForUI = taskBlocState.currentFilterOption; currentTagFilterForUI = taskBlocState.currentTagFilter; }
    final appThemeState = context.watch<ThemeCubit>().state;
    final isDarkMode = appThemeState == AppTheme.dark;
    final allBlocTasksForTagMenu = context.read<TaskBloc>().allTasksMasterList;
    final Set<String> uniqueTags = {};
    for (var task in allBlocTasksForTagMenu) { uniqueTags.addAll(task.tagList); }
    final sortedUniqueTags = uniqueTags.toList()..sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined), tooltip: isDarkMode ? "Switch to Light Theme" : "Switch to Dark Theme", onPressed: () => context.read<ThemeCubit>().toggleTheme()),
          if (sortedUniqueTags.isNotEmpty) PopupMenuButton<String?>(icon: const Icon(Icons.label_outline), tooltip: "Filter by Tag", initialValue: currentTagFilterForUI, onSelected: (tag) => context.read<TaskBloc>().add(ApplyTagFilter(tag)), itemBuilder: (c) => [const PopupMenuItem<String?>(value: null, child: Text('All Tags')), ...sortedUniqueTags.map((tag) => PopupMenuItem<String?>(value: tag, child: Text(tag)))]),
          PopupMenuButton<TaskFilterOption>(icon: const Icon(Icons.filter_list), tooltip: "Filter Tasks", initialValue: currentFilterForUI, onSelected: (opt) => context.read<TaskBloc>().add(ApplyTaskFilter(opt)), itemBuilder: (c) => TaskFilterOption.values.map((o) => PopupMenuItem<TaskFilterOption>(value: o, child: Text(_getFilterOptionText(o)))).toList()),
          PopupMenuButton<TaskSortOption>(icon: const Icon(Icons.sort), tooltip: "Sort Tasks", initialValue: currentSortForUI, onSelected: (opt) => context.read<TaskBloc>().add(ApplyTaskSort(opt)), itemBuilder: (c) => TaskSortOption.values.map((o) => (o == TaskSortOption.none && _getSortOptionText(o) == 'Default Order') ? null : PopupMenuItem<TaskSortOption>(value: o, child: Text(_getSortOptionText(o)))).whereType<PopupMenuItem<TaskSortOption>>().toList()),
          // NO Import/Export Menu
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= kTabletBreakpoint;
          return Column(
            children: [
              const NetworkStatusBanner(),
              Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 5), child: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Search tasks...', prefixIcon: const Icon(Icons.search, size: 22), suffixIcon: _textFieldQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => _searchController.clear()) : null))),
              if(currentTagFilterForUI != null && taskBlocState is TasksLoaded && (!isWideScreen || taskBlocState.detailPaneMode == DetailPaneMode.none)) 
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0), child: Align(alignment: Alignment.centerLeft, child: Chip(label: Text('Tag: $currentTagFilterForUI'), onDeleted: () => context.read<TaskBloc>().add(const ApplyTagFilter(null)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0)))),
              Expanded(
                child: BlocListener<TaskBloc, TaskState>(
                  listener: (ctx, state) {
                     if (state is TaskMutationSuccess) { _showFeedbackMessage(state.message, false); }
                     else if (state is TaskError) { _showFeedbackMessage("Task operation failed: ${state.message}", true); }
                     // NO DataTransfer listeners
                  },
                  child: BlocBuilder<TaskBloc, TaskState>(
                    builder: (context, state) {
                      if (state is TaskInitial || (state is TaskLoading && !(state is TasksLoaded))) { return const LoadingIndicator(); }
                      if (state is TaskError) { return ErrorMessageWidget(message: state.message, onRetry: () => context.read<TaskBloc>().add(const LoadTasks())); }
                      if (state is TasksLoaded) {
                        if (isWideScreen) {
                          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ Expanded(flex: 1, child: _buildTaskListPane(tasks: state.tasks, isWideScreen: true, selectedTaskId: state.selectedTaskIdForDetail, currentState: state)), const VerticalDivider(width: 1, thickness: 1), Expanded(flex: 2, child: _buildDetailPaneScaffold(context, state))]);
                        } else { 
                          return _buildTaskListPane(tasks: state.tasks, isWideScreen: false, selectedTaskId: null, currentState: state);
                        }
                      }
                      final blocCurrentState = BlocProvider.of<TaskBloc>(context, listen: false).state;
                      if (state is TaskLoading && blocCurrentState is TasksLoaded && blocCurrentState.tasks.isNotEmpty) {
                          return _buildTaskListPane(tasks: blocCurrentState.tasks, isWideScreen: isWideScreen, selectedTaskId: isWideScreen ? blocCurrentState.selectedTaskIdForDetail : null, currentState: blocCurrentState);
                      }
                      return const LoadingIndicator();
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (fabContext) {
          bool isWide = MediaQuery.of(fabContext).size.width >= kTabletBreakpoint;
          return FloatingActionButton(
            onPressed: () {
              if (isWide) { fabContext.read<TaskBloc>().add(ShowAddTaskFormInDetail()); }
              else { Navigator.of(fabContext).push(MaterialPageRoute(builder: (_) => BlocProvider.value(value: BlocProvider.of<TaskBloc>(fabContext), child: const TaskFormScreen())));}
            },
            tooltip: 'Add Task',
            child: const Icon(Icons.add),
          );
        }
      ),
    );
  }
}