import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<UserEntity> call({
    required String phoneNumber,
    required String otp,
  }) {
    return repository.verifyOtp(phoneNumber: phoneNumber, otp: otp);
  }

  Future<void> resend({required String phoneNumber}) {
    return repository.resendOtp(phoneNumber: phoneNumber);
  }
}

