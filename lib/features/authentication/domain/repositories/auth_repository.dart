import '../entities/user_entity.dart';
import '../../data/models/user_model.dart';

/// Abstract domain repository for authentication operations.
abstract class AuthRepository {
  Future<LoginResultModel> login({
    required String emailOrPhone,
    required String password,
    required bool rememberMe,
  });

  Future<LoginResultModel> refreshToken();

  bool get isLoggedIn;

  UserEntity? getSavedUser();

  Future<void> logout();

  Future<void> sendPhoneVerification({
    required String phoneNumber,
  });

  Future<UserEntity> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<void> resendOtp({
    required String phoneNumber,
  });

  Future<String> sendForgotPasswordReset({
    required String emailOrPhone,
  });

  Future<UserModel> getMe();

  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> fields,
    Map<String, String?>? filePaths,
  });
}
