import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/task_model.dart';
import '../bloc/task_bloc/task_bloc.dart';
import '../widgets/priority_selector.dart'; // Ensure this import is correct

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final VoidCallback? onSave;

  const TaskFormScreen({super.key, this.task, this.onSave});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late bool _isCompleted;
  late DateTime _createdDate;
  late TaskPriority _priority;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _tagsController = TextEditingController(text: widget.task?.tags ?? '');
    _isCompleted = widget.task?.isCompleted ?? false;
    _createdDate = widget.task?.createdDate ?? DateTime.now();
    _priority = widget.task?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final taskData = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isCompleted: _isCompleted,
        createdDate: _isEditing ? widget.task!.createdDate : DateTime.now(),
        priority: _priority,
        tags: _tagsController.text.trim(),
      );

      if (_isEditing) {
        context.read<TaskBloc>().add(UpdateTask(taskData));
      } else {
        context.read<TaskBloc>().add(AddTask(taskData));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if this screen is being pushed as a standalone route
    // or embedded (e.g. in a two-pane layout).
    // A common way is to check if there's a Scaffold ancestor provided by the navigator.
    // Or, a more explicit `isEmbedded` flag could be passed.
    final bool isStandaloneRoute = Scaffold.maybeOf(context) == null || (ModalRoute.of(context)?.isCurrent ?? false);
    // This check isn't perfect for all embedding scenarios but is a common heuristic.
    // If always embedded via _buildDetailPaneScaffold, then this Scaffold isn't strictly needed.
    // However, TaskFormScreen is also used for direct navigation on narrow screens.

    Widget formContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'Enter task title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Title cannot be empty';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (Optional)', hintText: 'Enter task description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(labelText: 'Tags (comma-separated)', hintText: 'e.g., work, important'),
            ),
            const SizedBox(height: 20),
            PrioritySelector(
              currentPriority: _priority,
              onChanged: (TaskPriority? value) { // <<< ENSURED onChanged IS PROVIDED
                if (value != null) {
                  setState(() {
                    _priority = value;
                  });
                }
              },
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Completed:', style: TextStyle(fontSize: 16)),
                  Switch(
                    value: _isCompleted,
                    onChanged: (value) {
                      setState(() { _isCompleted = value; });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Created: ${DateFormat.yMMMd().add_jm().format(_createdDate)}', style: TextStyle(color: Theme.of(context).hintColor)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'Save Changes' : 'Add Task'),
                onPressed: _submitForm,
              ),
            ),
          ],
        ),
      ),
    );
    
    // If not a standalone route (i.e., embedded), return just the form content.
    // The parent (e.g., _buildDetailPaneScaffold) provides the Scaffold and AppBar.
    if (!isStandaloneRoute && widget.onSave != null) { // A rough check; ideally pass `isEmbedded`
        return BlocListener<TaskBloc, TaskState>(
          // Listener for embedded scenario to trigger onSave, but no pop
          listener: (context, state) {
            if (state is TaskMutationSuccess) {
                widget.onSave?.call(); // Notify parent (e.g. TaskListScreen)
                // No Navigator.pop() here, parent handles UI update
            } else if (state is TaskError) {
                // Potentially show an inline error within the form area
                // or let parent handle global error snackbar
            }
          },
          child: formContent
        );
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Add New Task'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _submitForm)],
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskMutationSuccess) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ));
            widget.onSave?.call();
            if (Navigator.canPop(context)) { // Only pop if it's a standalone route
              Navigator.of(context).pop();
            }
          } else if (state is TaskError) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(SnackBar(
              content: Text("Error: ${state.message}"),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ));
          }
        },
        child: formContent,
      ),
    );
  }
}