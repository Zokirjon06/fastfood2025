import 'package:dartz/dartz.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';
import 'package:fastfood/layers/domain/repository/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<Either<String, UserEntity>> call({
    required String email,
    required String password,
  }) async {
    return await _authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
