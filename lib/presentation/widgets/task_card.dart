import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onDelete,
  });

  String _priorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return 'High';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.low: return 'Low';
    }
  }

  Widget _priorityChip(BuildContext context, TaskPriority priority) {
    final ThemeData theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;

    switch (priority) {
      case TaskPriority.high:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        break;
      case TaskPriority.medium:
        backgroundColor = theme.colorScheme.tertiaryContainer; // Example theme color
        textColor = theme.colorScheme.onTertiaryContainer;
        break;
      case TaskPriority.low:
        backgroundColor = theme.colorScheme.secondaryContainer; // Example theme color
        textColor = theme.colorScheme.onSecondaryContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _priorityText(priority),
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final tagList = task.tagList;
    final theme = Theme.of(context);

    return Card( // Card properties are now mostly from CardTheme
      child: InkWell( // Added InkWell for better tap feedback
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Match card shape
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 8, 12), // No left padding, leading checkbox handles it
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: onToggleComplete != null ? (bool? value) => onToggleComplete!() : null,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? theme.disabledColor : theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: task.isCompleted ? theme.disabledColor : theme.hintColor,
                        ),
                      ),
                    ],
                    if (tagList.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 4.0,
                        children: tagList.map((tag) => Chip(
                          label: Text(tag),
                          // Using ChipThemeData from AppThemes now
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat.yMMMd().add_jm().format(task.createdDate),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
                        ),
                        _priorityChip(context, task.priority),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null) // Keep delete icon if swipe-to-delete is not the only option
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 22),
                  tooltip: "Delete Task",
                  onPressed: () {
                    showDialog(
                         context: context,
                            builder: (BuildContext ctx) {
                              return AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: Text('Are you sure you want to delete "${task.title}"?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                                    child: const Text('Delete'),
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      onDelete!();
                                    },
                                  ),
                                ],
                              );
                            },
                      );
                  },
                )
              else
                const SizedBox(width: 8), // Keep spacing if no delete icon
            ],
          ),
        ),
      ),
    );
  }
}