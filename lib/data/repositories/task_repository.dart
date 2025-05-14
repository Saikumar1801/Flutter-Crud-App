import 'package:either_dart/either.dart'; // You might need to add this dependency
// or implement your own Either type
import '../../core/errors/failures.dart';
import '../models/task_model.dart';

// Let's add either_dart to pubspec.yaml
// dependencies:
//   either_dart: ^1.0.0

abstract class TaskRepository {
  Future<Either<Failure, List<Task>>> getTasks();
  Future<Either<Failure, Task>> getTaskById(String id);
  Future<Either<Failure, Task>> addTask(Task task);
  Future<Either<Failure, Task>> updateTask(Task task);
  Future<Either<Failure, void>> deleteTask(String id);
}