import 'package:dio/dio.dart';
import '../storage/preferences_service.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

/// Centralized Dio HTTP client configuration.
/// Injects authorization headers and handles automatic token refreshing on 401.
class DioClient {
  late final Dio dio;
  final PreferencesService? preferencesService;

  DioClient({this.preferencesService}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (preferencesService != null) {
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          preferencesService: preferencesService!,
        ),
      );
    }

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }
}
