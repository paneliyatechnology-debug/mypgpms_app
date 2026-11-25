import '../../data/models/user_model.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<LoginResultModel> call({
    required String emailOrPhone,
    required String password,
    required bool rememberMe,
  }) {
    return repository.login(
      emailOrPhone: emailOrPhone,
      password: password,
      rememberMe: rememberMe,
    );
  }
}
