import 'package:either_dart/either.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/logger.dart'; 
import '../datasources/local/task_local_datasource.dart';
import '../datasources/remote/task_remote_datasource.dart';
import '../models/task_model.dart';
import 'task_repository.dart';

typedef _VoidSuccess = Future<void> Function();
typedef _TaskSuccess = Future<Task> Function();

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Task>>> getTasks() async {
    appLogger.i("Attempting to get tasks. Network connected: ${await networkInfo.isConnected}");

    if (await networkInfo.isConnected) {
      try {
        final remoteTasks = await remoteDataSource.getTasks();
        appLogger.d("Fetched ${remoteTasks.length} tasks from remote.");

        await localDataSource.clearAllTasks();
        for (var task in remoteTasks) {
          await localDataSource.addTask(task);
        }

        return Right(remoteTasks);
      } on ServerException catch (e) {
        appLogger.e("ServerException in getTasks: ${e.message}", error: e);
        return Left(ServerFailure(e.message));
      } on CacheException catch (e) {
        appLogger.w("CacheException during remote-to-local sync: ${e.message}");
        return Left(CacheFailure('Failed to cache tasks after fetching: ${e.message}'));
      }
    } else {
      appLogger.w("Network offline. Fetching tasks from local cache.");
      try {
        final localTasks = await localDataSource.getTasks();
        if (localTasks.isNotEmpty) {
          appLogger.d("Fetched ${localTasks.length} tasks from local cache.");
          return Right(localTasks);
        } else {
          appLogger.w("Local cache is empty.");
          return Left(CacheFailure('No tasks found in cache and no network connection.'));
        }
      } on CacheException catch (e) {
        appLogger.e("CacheException while offline: ${e.message}", error: e);
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Task>> getTaskById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteTask = await remoteDataSource.getTaskById(id);
        await localDataSource.addTask(remoteTask);
        return Right(remoteTask);
      } on ServerException catch (e) {
        try {
          final localTask = await localDataSource.getTaskById(id);
          return Right(localTask);
        } on CacheException {
          return Left(ServerFailure('${e.message} (and not found in cache)'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure('Failed to cache task $id after fetching: ${e.message}'));
      }
    } else {
      try {
        final localTask = await localDataSource.getTaskById(id);
        return Right(localTask);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  Future<Either<Failure, Task>> _taskMutation(_TaskSuccess remoteCall, Task taskToCache) async {
    if (await networkInfo.isConnected) {
      try {
        final resultTask = await remoteCall();
        await localDataSource.addTask(resultTask);
        return Right(resultTask);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure('Operation succeeded remotely but failed to update local cache: ${e.message}'));
      }
    } else {
      return Left(NetworkFailure('No network connection. Operation not performed.'));
    }
  }

  @override
  Future<Either<Failure, Task>> addTask(Task task) async {
    return _taskMutation(() => remoteDataSource.addTask(task), task);
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    return _taskMutation(() => remoteDataSource.updateTask(task), task);
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteTask(id);
        try {
          await localDataSource.deleteTask(id);
        } on CacheException catch (e) {
          appLogger.w("Warning: Task $id deleted from remote but failed to delete from local cache: ${e.message}");
        }
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No network connection. Deletion not performed.'));
    }
  }
}
