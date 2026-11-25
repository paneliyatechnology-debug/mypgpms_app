import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResultModel> login({
    required String emailOrPhone,
    required String password,
    required bool rememberMe,
  });

  Future<LoginResultModel> refreshToken({required String refreshToken});

  Future<void> sendPhoneVerification({required String phoneNumber});

  Future<UserModel> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<void> resendOtp({required String phoneNumber});

  Future<String> sendForgotPasswordReset({required String emailOrPhone});

  Future<UserModel> getMe();

  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> fields,
    Map<String, String?>? filePaths,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<LoginResultModel> login({
    required String emailOrPhone,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.login,
        data: {
          'email': emailOrPhone,
          'password': password,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final result = LoginResultModel.fromJson(data);
        if (result.success && result.user != null) {
          return result;
        } else {
          throw ServerException(
            message: result.message.isNotEmpty ? result.message : 'Login failed',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw const ServerException(message: 'Invalid response format from server');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to connect to server. Please try again.';
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData['errors'] is List && (errorData['errors'] as List).isNotEmpty) {
          final firstError = (errorData['errors'] as List).first;
          if (firstError is Map && firstError['message'] != null) {
            errorMessage = firstError['message'].toString();
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }
      throw ServerException(message: errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<LoginResultModel> refreshToken({required String refreshToken}) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.refresh,
        data: {
          'refresh_token': refreshToken,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final result = LoginResultModel.fromJson(data);
        if (result.success && result.accessToken != null) {
          return result;
        } else {
          throw ServerException(
            message: result.message.isNotEmpty ? result.message : 'Failed to refresh token',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw const ServerException(message: 'Invalid response format from server');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to refresh token';
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }
      throw ServerException(message: errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> sendPhoneVerification({required String phoneNumber}) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<UserModel> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return UserModel(
      id: 'user_101',
      name: 'John Resident',
      email: 'john.resident@mypgpms.app',
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<void> resendOtp({required String phoneNumber}) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<String> sendForgotPasswordReset({required String emailOrPhone}) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {
          'email': emailOrPhone,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final bool success = data['success'] as bool? ?? false;
        final String message = data['message'] as String? ??
            'Password reset link has been sent to your email address.';
        if (success) {
          return message;
        } else {
          throw ServerException(
            message: message.isNotEmpty ? message : 'Failed to send password reset link',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw const ServerException(message: 'Invalid response format from server');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to connect to server. Please try again.';
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData['errors'] is List && (errorData['errors'] as List).isNotEmpty) {
          final firstError = (errorData['errors'] as List).first;
          if (firstError is Map && firstError['message'] != null) {
            errorMessage = firstError['message'].toString();
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }
      throw ServerException(message: errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.getMe);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final bool success = data['success'] as bool? ?? false;
        final rawData = data['data'];
        final Map<String, dynamic>? userData = (rawData is Map<String, dynamic>)
            ? (rawData['user'] is Map<String, dynamic>
                ? rawData['user'] as Map<String, dynamic>
                : rawData)
            : null;

        if (success && userData != null) {
          return UserModel.fromJson(userData);
        } else {
          throw ServerException(
            message: data['message']?.toString() ?? 'Failed to fetch user',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw const ServerException(message: 'Invalid response format from server');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch authenticated user';
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }
      throw ServerException(message: errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> fields,
    Map<String, String?>? filePaths,
  }) async {
    try {
      final map = <String, dynamic>{};
      for (final entry in fields.entries) {
        if (entry.value != null) {
          map[entry.key] = entry.value.toString();
        }
      }
      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          final path = entry.value;
          if (path != null && path.isNotEmpty) {
            final file = File(path);
            if (await file.exists()) {
              final filename = path.split(Platform.pathSeparator).last;
              map[entry.key] = await MultipartFile.fromFile(
                path,
                filename: filename,
              );
            }
          }
        }
      }

      final formData = FormData.fromMap(map);
      final response = await dioClient.dio.put(
        ApiEndpoints.updateProfile,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final bool success = data['success'] as bool? ?? (response.statusCode == 200 || response.statusCode == 201);
        if (success) {
          return data;
        } else {
          throw ServerException(
            message: data['message']?.toString() ?? 'Profile update failed',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw const ServerException(message: 'Invalid response format from server');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update profile. Please try again.';
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'].toString();
        } else if (errorData['errors'] is List && (errorData['errors'] as List).isNotEmpty) {
          final first = (errorData['errors'] as List).first;
          if (first is Map && first['message'] != null) {
            errorMessage = first['message'].toString();
          } else {
            errorMessage = first.toString();
          }
        }
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }
      throw ServerException(message: errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
