import 'package:dartz/dartz.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';
import 'package:fastfood/layers/domain/repository/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<bool>call(UserEntity login) async {
    return await _authRepository.login(login);
  }
}
