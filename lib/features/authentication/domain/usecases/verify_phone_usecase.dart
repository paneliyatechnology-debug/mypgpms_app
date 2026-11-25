import '../repositories/auth_repository.dart';

class VerifyPhoneUseCase {
  final AuthRepository repository;

  VerifyPhoneUseCase(this.repository);

  Future<void> call({required String phoneNumber}) {
    return repository.sendPhoneVerification(phoneNumber: phoneNumber);
  }
}

