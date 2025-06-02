import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';
import 'package:fastfood/layers/domain/usecase/login_usecase.dart';
import 'package:fastfood/layers/domain/repository/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
   AuthCubit({
    required LoginUseCase loginUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        super(const AuthState());

  final LoginUseCase _loginUseCase;

 
  Future<void> login(UserEntity login) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      final result = await _loginUseCase(login);

      if (result) {
        emit(state.copyWith(status: AuthStatus.success));
      } else {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Qaytadan urinib ko\'ring', // "try again"
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Qaytadan urinib ko\'ring', // "try again"
      ));
    }
  }
}
