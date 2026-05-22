import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/repository/auth_repository.dart';
import '../../features/vision/bloc/vision_bloc.dart';
import '../../features/vision/repository/vision_repository.dart';
import '../../features/vision/services/mlkit_vision_service.dart';
import '../../features/generative/bloc/generative_bloc.dart';
import '../../features/generative/repository/generative_repository.dart';
import '../../features/datahub/repository/datahub_repository.dart';
import '../../features/quiz/repository/quiz_repository.dart';
import '../../features/quiz/bloc/quiz_bloc.dart';
import '../../features/eco_smart/repository/eco_smart_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
    final defaultBaseUrl =
      kIsWeb ? 'http://127.0.0.1:8000/api/v1' : 'http://127.0.0.1:8000/api/v1';

  final apiBaseUrl = const bool.hasEnvironment('API_BASE_URL')
      ? const String.fromEnvironment('API_BASE_URL')
      : defaultBaseUrl;

  // External
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  const secureStorage = FlutterSecureStorage();
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);

  // Network
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(secureStorage));
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  getIt.registerSingleton<Dio>(dio);
  getIt.registerSingleton<ApiClient>(ApiClient(dio));

  // Services
  getIt.registerLazySingleton<MLKitVisionService>(() => MLKitVisionService());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<ApiClient>(), getIt<FlutterSecureStorage>()),
  );
  getIt.registerLazySingleton<VisionRepository>(
    () => VisionRepository(getIt<ApiClient>(), getIt<MLKitVisionService>()),
  );
  getIt.registerLazySingleton<GenerativeRepository>(
    () => GenerativeRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<DataHubRepository>(
    () => DataHubRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<QuizRepository>(
    () => QuizRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<EcoSmartRepository>(
    () => EcoSmartRepository(getIt<ApiClient>()),
  );

  // Blocs
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()));
  getIt.registerFactory<VisionBloc>(
    () => VisionBloc(getIt<VisionRepository>()),
  );
  getIt.registerFactory<GenerativeBloc>(
    () => GenerativeBloc(
      getIt<GenerativeRepository>(),
      getIt<QuizRepository>(),
    ),
  );
  getIt.registerFactory<QuizBloc>(() => QuizBloc(getIt<QuizRepository>()));
}
