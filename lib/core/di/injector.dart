import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../network/network_info.dart';
import '../../data/datasources/local/task_local_datasource.dart';
import '../../data/datasources/remote/task_remote_datasource.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../presentation/bloc/task_bloc/task_bloc.dart';
import '../../presentation/theme_cubit/theme_cubit.dart';
// NO DataTransferService import

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Connectivity());

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  
  // Services
  // NO DataTransferService registration

  // Data sources
  sl.registerLazySingleton<TaskLocalDataSource>(() => TaskLocalDataSourceImpl());
  sl.registerLazySingleton<TaskRemoteDataSource>(() => TaskRemoteDataSourceImpl(client: sl()));

  // Repository
  sl.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Blocs / Cubits
  sl.registerFactory(() => TaskBloc(
        taskRepository: sl(),
        // NO DataTransferService injection
      ));
  sl.registerLazySingleton(() => ThemeCubit());
}