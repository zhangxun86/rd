import 'package:flutter_network_kit/flutter_network_kit.dart';
import 'package:get_it/get_it.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';

final getIt = GetIt.instance;

Future<void> initDI() async {
  // --- Framework Initialization ---
  await FlutterNetworkKit.initialize();

  // --- Business Layer Dependencies ---

  // Auth Feature
  getIt.registerLazySingleton(() => AuthRemoteDataSource(getIt<Dio>()));
  getIt.registerLazySingleton(() => AuthLocalDataSource());
  getIt.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>(), getIt<AuthLocalDataSource>()),
  );
}