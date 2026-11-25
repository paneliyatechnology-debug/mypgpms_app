import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required Map<String, dynamic> fields,
    Map<String, String?>? filePaths,
  }) {
    return repository.updateProfile(
      fields: fields,
      filePaths: filePaths,
    );
  }
}
