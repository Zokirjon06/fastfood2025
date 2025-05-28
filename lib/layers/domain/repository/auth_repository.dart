import 'package:dartz/dartz.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';

abstract class AuthRepository {
  Future<Either<String, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<String, void>> signOut();

  Future<Either<String, UserEntity?>> getCurrentUser();

  Stream<UserEntity?> get authStateChanges;
}
