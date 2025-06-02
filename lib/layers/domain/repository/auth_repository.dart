import 'package:dartz/dartz.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';

abstract class AuthRepository {
  Future<bool> login(UserEntity login);

  // Future<Either<String, UserEntity?>> getCurrentUser();

  // Stream<UserEntity?> get authStateChanges;
}
