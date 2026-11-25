import '../../data/models/user_model.dart';
import '../repositories/auth_repository.dart';

class GetMeUseCase {
  final AuthRepository repository;

  GetMeUseCase(this.repository);

  Future<UserModel> call() {
    return repository.getMe();
  }
}
