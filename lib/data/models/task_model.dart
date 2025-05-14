import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high }

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdDate;
  final TaskPriority priority;
  final String tags; // Comma-separated string for tags

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    DateTime? createdDate,
    this.priority = TaskPriority.medium,
    this.tags = '',
  })  : id = id ?? Uuid().v4(),
        createdDate = createdDate ?? DateTime.now();

  List<String> get tagList => tags.isEmpty ? [] : tags.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

  @override
  List<Object?> get props => [id, title, description, isCompleted, createdDate, priority, tags];

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdDate,
    TaskPriority? priority,
    String? tags,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate ?? this.createdDate,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdDate': createdDate.toIso8601String(),
      'priority': priority.toString().split('.').last,
      'tags': tags,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdDate: DateTime.parse(json['createdDate'] as String),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      tags: json['tags'] as String? ?? '',
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'createdDate': createdDate.toIso8601String(),
      'priority': priority.toString().split('.').last,
      'tags': tags,
    };
  }

  factory Task.fromDbMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      isCompleted: (map['isCompleted'] as int) == 1,
      createdDate: DateTime.parse(map['createdDate'] as String),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      tags: map['tags'] as String? ?? '',
    );
  }
}