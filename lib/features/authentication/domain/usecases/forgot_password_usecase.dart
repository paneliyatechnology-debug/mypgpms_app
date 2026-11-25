import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<String> call({required String emailOrPhone}) {
    return repository.sendForgotPasswordReset(emailOrPhone: emailOrPhone);
  }
}

