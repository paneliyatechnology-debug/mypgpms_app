import '../../data/models/user_model.dart';
import '../repositories/auth_repository.dart';

class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  Future<LoginResultModel> call() {
    return repository.refreshToken();
  }
}
