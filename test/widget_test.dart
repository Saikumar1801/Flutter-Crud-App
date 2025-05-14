import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_crud_app/core/di/injector.dart' as di_injector;
import 'package:flutter_crud_app/main.dart';
import 'package:flutter_crud_app/presentation/bloc/task_bloc/task_bloc.dart';
import 'package:flutter_crud_app/presentation/bloc/task_bloc/task_filter_sort_values.dart';
import 'package:flutter_crud_app/presentation/theme_cubit/theme_cubit.dart';
import 'package:flutter_crud_app/data/models/task_model.dart';
import 'package:flutter_crud_app/core/network/network_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mocks
class MockTaskBloc extends MockBloc<TaskEvent, TaskState> implements TaskBloc {}
class MockThemeCubit extends MockCubit<AppTheme> implements ThemeCubit {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

// Fakes
class FakeTask extends Fake implements Task {}
class FakeTaskEvent extends Fake implements TaskEvent {}

void main() {
  setUpAll(() {
    di_injector.sl.reset(dispose: false);
    di_injector.sl.allowReassignment = true;

    SharedPreferences.setMockInitialValues({});

    registerFallbackValue(FakeTask());
    registerFallbackValue(FakeTaskEvent());

    // ThemeCubit mock setup
    final mockThemeCubitInstance = MockThemeCubit();
    when(() => mockThemeCubitInstance.state).thenReturn(AppTheme.light);
    when(() => mockThemeCubitInstance.stream).thenAnswer((_) => Stream.value(AppTheme.light));
    when(() => mockThemeCubitInstance.toggleTheme()).thenReturn(null);
    di_injector.sl.registerLazySingleton<ThemeCubit>(() => mockThemeCubitInstance);

    // TaskBloc mock setup
    final mockTaskBlocInstance = MockTaskBloc();
    final initialTaskState = TasksLoaded(
        const [],
        currentSortOption: TaskSortOption.createdDateDesc,
        currentFilterOption: TaskFilterOption.all,
        currentTagFilter: null);
    when(() => mockTaskBlocInstance.state).thenReturn(initialTaskState);
    when(() => mockTaskBlocInstance.stream).thenAnswer((_) => Stream.value(initialTaskState));
    when(() => mockTaskBlocInstance.add(any<TaskEvent>())).thenReturn(null);
    when(() => mockTaskBlocInstance.currentSearchQuery).thenReturn('');
    // Stub the new public getter used by TaskListScreen
    when(() => mockTaskBlocInstance.allTasksMasterList).thenReturn(const []); // <<< CORRECTED STUB
    // Stub other public getters from TaskBloc if your UI uses them directly
    when(() => mockTaskBlocInstance.currentSortOptionFromBloc).thenReturn(TaskSortOption.createdDateDesc);
    when(() => mockTaskBlocInstance.currentFilterOptionFromBloc).thenReturn(TaskFilterOption.all);
    when(() => mockTaskBlocInstance.currentTagFilterFromBloc).thenReturn(null);


    di_injector.sl.registerLazySingleton<TaskBloc>(() => mockTaskBlocInstance);

    // NetworkInfo mock
    final mockNetworkInfoInstance = MockNetworkInfo();
    when(() => mockNetworkInfoInstance.isConnected).thenAnswer((_) async => true);
    when(() => mockNetworkInfoInstance.onConnectivityChanged)
        .thenAnswer((_) => Stream.value(ConnectivityResult.wifi).asBroadcastStream());
    di_injector.sl.registerLazySingleton<NetworkInfo>(() => mockNetworkInfoInstance);
  });


  testWidgets('TaskListScreen displays AppBar title, FAB, and empty state message',
      (WidgetTester tester) async {
    
    await tester.pumpWidget(const MyApp());

    await tester.pumpAndSettle();

    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('No tasks yet!'), findsOneWidget);
  });
}