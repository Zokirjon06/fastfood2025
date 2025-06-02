import 'package:firebase_auth/firebase_auth.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<bool> login(UserEntity login) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
              email: login.email, password: login.password);

      if (userCredential.user == null) {
        return false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.message}');
      return false; // Return false instead of throwing
    } catch (e) {
      debugPrint('Login Error: ${e.toString()}');
      return false; // Return false for any other errors
    }
  }

  // Future<bool> getCurrentUser() async {
  //   try {
  //     final User? user = _firebaseAuth.currentUser;
  //     if (user != null) {
  //       return true;
  //     }
  //     return false;
  //   } catch (e) {
  //     throw Exception('Failed to get current user: ${e.toString()}');
  //   }
  // }
}
