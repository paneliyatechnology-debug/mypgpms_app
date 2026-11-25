import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  bool call() => repository.isLoggedIn;

  UserEntity? getSavedUser() => repository.getSavedUser();
}
