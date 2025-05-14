import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class PrioritySelector extends StatelessWidget {
  final TaskPriority currentPriority;
  final ValueChanged<TaskPriority?> onChanged;

  const PrioritySelector({
    super.key,
    required this.currentPriority,
    required this.onChanged,
  });

  Widget _buildRadioTile(String title, TaskPriority value, Color activeColor) {
    // Using Flexible or Expanded inside a Row would be another way
    // For Wrap, controlling width is often simpler.
    return SizedBox(
      width: 150, // Adjust this based on your layout needs
      child: RadioListTile<TaskPriority>(
        title: Text(title),
        value: value,
        groupValue: currentPriority,
        onChanged: onChanged,
        activeColor: activeColor,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priority:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        LayoutBuilder(
          builder: (context, constraints) {
            // You can adjust this breakpoint
            if (constraints.maxWidth > 360) {
              // Use Wrap for wider screens to arrange items horizontally
              return Wrap(
                spacing: 0.0, // Horizontal space between children
                runSpacing: 0.0, // Vertical space if items wrap to next line
                children: <Widget>[
                  _buildRadioTile('Low', TaskPriority.low, Colors.green.shade400),
                  _buildRadioTile('Medium', TaskPriority.medium, Colors.orange.shade400),
                  _buildRadioTile('High', TaskPriority.high, Colors.red.shade400),
                ],
              );
            } else {
              // Default column layout for narrower screens
              return Column(
                children: [
                  _buildRadioTile('High', TaskPriority.high, Colors.red.shade400),
                  _buildRadioTile('Medium', TaskPriority.medium, Colors.orange.shade400),
                  _buildRadioTile('Low', TaskPriority.low, Colors.green.shade400),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}