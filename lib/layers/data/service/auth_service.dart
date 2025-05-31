import 'package:firebase_auth/firebase_auth.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw Exception('User not found');
      }

      return _mapFirebaseUserToUserEntity(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }



  Future<UserEntity?> getCurrentUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user != null) {
        return _mapFirebaseUserToUserEntity(user);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((User? user) {
      return user != null ? _mapFirebaseUserToUserEntity(user) : null;
    });
  }

  UserEntity _mapFirebaseUserToUserEntity(User user) {
    return UserEntity(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
