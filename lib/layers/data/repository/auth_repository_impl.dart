import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fastfood/layers/data/service/auth_service.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';
import 'package:fastfood/layers/domain/repository/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<bool> login(UserEntity login) async{
    return _authService.login(login);
  }
}
