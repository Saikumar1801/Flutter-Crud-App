import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injector.dart' as di;
import 'presentation/bloc/task_bloc/task_bloc.dart';
import 'presentation/screens/task_list_screen.dart';
import 'presentation/theme_cubit/theme_cubit.dart';
import 'core/utils/app_themes.dart'; // Import AppThemes for static access

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider( // Use MultiBlocProvider if you have more than one top-level provider
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => di.sl<ThemeCubit>(),
        ),
        BlocProvider<TaskBloc>(
          create: (context) => di.sl<TaskBloc>()..add(const LoadTasks()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, AppTheme>(
        builder: (context, appTheme) {
          return MaterialApp(
            title: 'Flutter CRUD App',
            theme: AppThemes.lightTheme, // Provide the light theme
            darkTheme: AppThemes.darkTheme, // Provide the dark theme
            themeMode: appTheme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light, // Control active theme
            debugShowCheckedModeBanner: false,
            home: const TaskListScreen(),
          );
        },
      ),
    );
  }
}