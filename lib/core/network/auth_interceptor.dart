import 'dart:async';
import 'package:dio/dio.dart';
import '../../injection_container.dart' as di;
import '../storage/preferences_service.dart';
import 'api_endpoints.dart';
import 'socket_service.dart';

/// Interceptor that attaches authorization tokens and automatically
/// refreshes the access token when an HTTP 401 Unauthorized response is received.
class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final PreferencesService preferencesService;
  final Dio _tokenDio;

  Completer<bool>? _refreshCompleter;

  AuthInterceptor({
    required this.dio,
    required this.preferencesService,
  }) : _tokenDio = Dio(
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

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final accessToken = preferencesService.accessToken;
    final refreshToken = preferencesService.refreshToken;

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
      if (refreshToken != null && refreshToken.isNotEmpty) {
        options.headers['Cookie'] = 'access_token=$accessToken; refresh_token=$refreshToken';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final path = err.requestOptions.path;

    // Do not attempt token refresh for auth endpoints to prevent recursion
    final isAuthEndpoint = path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.refresh) ||
        path.contains(ApiEndpoints.forgotPassword);

    if (response?.statusCode == 401 && !isAuthEndpoint) {
      final savedRefreshToken = preferencesService.refreshToken;

      if (savedRefreshToken == null || savedRefreshToken.isEmpty) {
        await preferencesService.clearAuth();
        return handler.next(err);
      }

      // If a refresh is already in progress, await its result
      if (_refreshCompleter != null) {
        final success = await _refreshCompleter!.future;
        if (success) {
          final retried = await _retry(err.requestOptions);
          return handler.resolve(retried);
        } else {
          return handler.next(err);
        }
      }

      _refreshCompleter = Completer<bool>();

      try {
        final refreshResponse = await _tokenDio.post(
          ApiEndpoints.refresh,
          data: {
            'refresh_token': savedRefreshToken,
          },
        );

        final data = refreshResponse.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final payload = data['data'] as Map<String, dynamic>?;
          final newAccessToken = payload?['access_token']?.toString() ?? '';
          final newRefreshToken = payload?['refresh_token']?.toString() ?? savedRefreshToken;
          final user = payload?['user'] as Map<String, dynamic>?;

          await preferencesService.updateTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            user: user,
            fullResponse: data,
          );

          try {
            di.sl<SocketService>().connect(customToken: newAccessToken);
          } catch (_) {}

          _refreshCompleter?.complete(true);
          _refreshCompleter = null;

          // Retry the original failed request with the new access token
          final retried = await _retry(err.requestOptions);
          return handler.resolve(retried);
        } else {
          await preferencesService.clearAuth();
          try {
            di.sl<SocketService>().disconnect();
          } catch (_) {}
          _refreshCompleter?.complete(false);
          _refreshCompleter = null;
          return handler.next(err);
        }
      } catch (refreshError) {
        await preferencesService.clearAuth();
        _refreshCompleter?.complete(false);
        _refreshCompleter = null;
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final accessToken = preferencesService.accessToken;
    final refreshToken = preferencesService.refreshToken;

    final options = Options(
      method: requestOptions.method,
      headers: Map<String, dynamic>.from(requestOptions.headers)
        ..['Authorization'] = 'Bearer $accessToken'
        ..['Cookie'] = 'access_token=$accessToken; refresh_token=$refreshToken',
      contentType: requestOptions.contentType,
      responseType: requestOptions.responseType,
    );

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
