import 'package:dartz/dartz.dart';
import 'package:fastfood/layers/data/service/auth_service.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';
import 'package:fastfood/layers/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<Either<String, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(user);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> signOut() async {
    try {
      await _authService.signOut();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => _authService.authStateChanges;
}
