import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final PreferencesService preferencesService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.preferencesService,
  });

  @override
  Future<LoginResultModel> login({
    required String emailOrPhone,
    required String password,
    required bool rememberMe,
  }) async {
    final result = await remoteDataSource.login(
      emailOrPhone: emailOrPhone,
      password: password,
      rememberMe: rememberMe,
    );

    if (result.success && result.user != null) {
      await preferencesService.saveLoginResponse(
        responseJson: result.rawJson,
        rememberMe: rememberMe,
      );
    }

    return result;
  }

  @override
  Future<LoginResultModel> refreshToken() async {
    final savedRefreshToken = preferencesService.refreshToken;
    if (savedRefreshToken == null || savedRefreshToken.isEmpty) {
      throw const ServerException(message: 'No refresh token available');
    }

    final result = await remoteDataSource.refreshToken(refreshToken: savedRefreshToken);
    if (result.success && result.accessToken != null) {
      await preferencesService.updateTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken ?? savedRefreshToken,
        user: result.user?.toJson(),
        fullResponse: result.rawJson,
      );
    }
    return result;
  }

  @override
  bool get isLoggedIn => preferencesService.isLoggedIn;

  @override
  UserEntity? getSavedUser() {
    final userMap = preferencesService.getSavedUser();
    if (userMap != null) {
      return UserModel.fromJson(userMap);
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await preferencesService.clearAuth();
  }

  @override
  Future<void> sendPhoneVerification({required String phoneNumber}) {
    return remoteDataSource.sendPhoneVerification(phoneNumber: phoneNumber);
  }

  @override
  Future<UserEntity> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) {
    return remoteDataSource.verifyOtp(phoneNumber: phoneNumber, otp: otp);
  }

  @override
  Future<void> resendOtp({required String phoneNumber}) {
    return remoteDataSource.resendOtp(phoneNumber: phoneNumber);
  }

  @override
  Future<String> sendForgotPasswordReset({required String emailOrPhone}) {
    return remoteDataSource.sendForgotPasswordReset(emailOrPhone: emailOrPhone);
  }

  @override
  Future<UserModel> getMe() async {
    final user = await remoteDataSource.getMe();
    await preferencesService.saveUserData(
      user.rawJson.isNotEmpty ? user.rawJson : user.toJson(),
    );
    return user;
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> fields,
    Map<String, String?>? filePaths,
  }) {
    return remoteDataSource.updateProfile(
      fields: fields,
      filePaths: filePaths,
    );
  }
}
