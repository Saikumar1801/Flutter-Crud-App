// test/data/repositories/task_repository_impl_test.dart
import 'package:either_dart/either.dart';
import 'package:flutter_crud_app/core/errors/exceptions.dart';
import 'package:flutter_crud_app/core/errors/failures.dart';
import 'package:flutter_crud_app/core/network/network_info.dart';
import 'package:flutter_crud_app/data/datasources/local/task_local_datasource.dart';
import 'package:flutter_crud_app/data/datasources/remote/task_remote_datasource.dart';
import 'package:flutter_crud_app/data/models/task_model.dart';
import 'package:flutter_crud_app/data/repositories/task_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}
class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}
class FakeTask extends Fake implements Task {}

void main() {
  late TaskRepositoryImpl repository;
  late MockTaskRemoteDataSource mockRemoteDataSource;
  late MockTaskLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() {
    registerFallbackValue(FakeTask());
  });

  setUp(() {
    mockRemoteDataSource = MockTaskRemoteDataSource();
    mockLocalDataSource = MockTaskLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = TaskRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  final tTask1 = Task(id: '1', title: 'Test Task 1');
  final tTask2 = Task(id: '2', title: 'Test Task 2');
  final tTaskList = [tTask1, tTask2];

  group('getTasks', () {
    test('should return remote data when online and cache it', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getTasks()).thenAnswer((_) async => tTaskList);
      when(() => mockLocalDataSource.clearAllTasks()).thenAnswer((_) async {});
      when(() => mockLocalDataSource.addTask(any<Task>())).thenAnswer((_) async {});

      final result = await repository.getTasks();

      expect(result, Right(tTaskList));
      verify(() => mockRemoteDataSource.getTasks()).called(1);
      verify(() => mockLocalDataSource.clearAllTasks()).called(1);
      verify(() => mockLocalDataSource.addTask(tTask1)).called(1);
      verify(() => mockLocalDataSource.addTask(tTask2)).called(1);
    });

    test('should return ServerFailure when remote call fails and online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getTasks()).thenThrow(ServerException('Server Error'));

      final result = await repository.getTasks();

      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      verify(() => mockRemoteDataSource.getTasks()).called(1);
      verifyNever(() => mockLocalDataSource.getTasks());
    });

    test('should return local data when offline and cache is not empty', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getTasks()).thenAnswer((_) async => tTaskList);

      final result = await repository.getTasks();

      expect(result, Right(tTaskList));
      verifyNever(() => mockRemoteDataSource.getTasks());
      verify(() => mockLocalDataSource.getTasks()).called(1);
    });

    test('should return CacheFailure when offline and cache is empty', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getTasks()).thenAnswer((_) async => []);

      final result = await repository.getTasks();

      expect(result.isLeft, true);
      expect(result.left, isA<CacheFailure>());
      verify(() => mockLocalDataSource.getTasks()).called(1);
    });
  });

  group('addTask', () {
    final tTaskToAdd = Task(title: 'New Task');
    final tTaskAddedByRemote = tTaskToAdd.copyWith(id: 'remote-id');

    test('should call remote and local data source when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.addTask(tTaskToAdd)).thenAnswer((_) async => tTaskAddedByRemote);
      when(() => mockLocalDataSource.addTask(tTaskAddedByRemote)).thenAnswer((_) async {});

      final result = await repository.addTask(tTaskToAdd);

      expect(result, Right(tTaskAddedByRemote));
      verify(() => mockRemoteDataSource.addTask(tTaskToAdd)).called(1);
      verify(() => mockLocalDataSource.addTask(tTaskAddedByRemote)).called(1);
    });

    test('should return NetworkFailure when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.addTask(tTaskToAdd);

      expect(result.isLeft, true);
      expect(result.left, isA<NetworkFailure>());
      verifyNever(() => mockRemoteDataSource.addTask(any<Task>()));
      verifyNever(() => mockLocalDataSource.addTask(any<Task>()));
    });
  });

  group('deleteTask', () {
    const tTaskId = '1';
    test('should call remote and local data source to delete when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true); 
      when(() => mockRemoteDataSource.deleteTask(tTaskId)).thenAnswer((_) async {});
      when(() => mockLocalDataSource.deleteTask(tTaskId)).thenAnswer((_) async {});

      final result = await repository.deleteTask(tTaskId);

      expect(result.isRight, isTrue); 
      verify(() => mockRemoteDataSource.deleteTask(tTaskId)).called(1);
      verify(() => mockLocalDataSource.deleteTask(tTaskId)).called(1);
    });

     test('should return NetworkFailure when offline for deleteTask', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false); 

      final result = await repository.deleteTask(tTaskId);

      expect(result.isLeft, true);
      expect(result.left, isA<NetworkFailure>());
      verifyNever(() => mockRemoteDataSource.deleteTask(any()));
      verifyNever(() => mockLocalDataSource.deleteTask(any()));
    });
  });
}