import 'package:dio/dio.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import 'package:get_it/get_it.dart';

// Import your custom services and interceptors
import 'common/interceptors/alice_interceptor.dart';
import 'features/feedback/data/datasources/feedback_remote_datasource.dart';
import 'features/feedback/data/repositories/feedback_repository_impl.dart';
import 'features/feedback/domain/repositories/feedback_repository.dart';
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'services/device_info_service.dart';
import 'common/interceptors/common_params_interceptor.dart';

// Import your business layer dependencies
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';

// You can still import and use Alice or other debug tools here
import 'package:alice/alice.dart';

/// Global service locator instance.
final getIt = GetIt.instance;

/// Asynchronously initializes all dependencies for the application.
/// This function should be called in `main.dart` before `runApp()`.
Future<void> initDI() async {

  // --- 1. Application-Specific Services Setup ---

  // Create and initialize the DeviceInfoService. We register it as a singleton
  // so the same instance can be accessed throughout the app.
  final deviceInfoService = DeviceInfoService();
  await deviceInfoService.init(); // Await initialization to ensure info is ready.
  getIt.registerSingleton<DeviceInfoService>(deviceInfoService);

  // --- 2. Custom Interceptors Setup ---

  // Create instances of all custom interceptors your app needs.
  final commonParamsInterceptor = AppCommonParamsInterceptor();

  // Example: Setting up Alice for debugging
  final alice = Alice();
  final aliceInterceptor = AliceDioInterceptor(alice);

  // --- 3. Framework Initialization with Injection ---

  // Initialize the core network framework, injecting the custom interceptors.
  // The framework is now configured with your app's specific needs.
  await FlutterNetworkKit.initialize(
    extraInterceptors: [
      commonParamsInterceptor,
      aliceInterceptor, // Add your debug interceptor here
    ],
  );

  // --- 4. Business Layer Dependencies Registration ---

  // Register all feature-specific datasources and repositories.
  // They will automatically get the fully configured Dio instance
  // that was registered inside FlutterNetworkKit.initialize().

  // Auth Feature
  getIt.registerLazySingleton(() => AuthRemoteDataSource(getIt<Dio>()));
  getIt.registerLazySingleton(() => AuthLocalDataSource());
  getIt.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      getIt<AuthRemoteDataSource>(),
      getIt<AuthLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton(() => FeedbackRemoteDataSource(getIt<Dio>()));
  getIt.registerLazySingleton<FeedbackRepository>(() => FeedbackRepositoryImpl(getIt()));
  getIt.registerLazySingleton(() => ProfileRemoteDataSource(getIt<Dio>()));
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(getIt()));
}