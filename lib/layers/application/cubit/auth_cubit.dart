import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';
import 'package:fastfood/layers/domain/usecase/login_usecase.dart';
import 'package:fastfood/layers/domain/repository/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final AuthRepository _authRepository;
  late StreamSubscription<UserEntity?> _authStateSubscription;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _authRepository = authRepository,
        super(const AuthState()) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) {
        if (user != null) {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            isLoading: false,
          ));
        } else {
          emit(state.copyWith(
            status: AuthStatus.unauthenticated,
            user: null,
            isLoading: false,
          ));
        }
      },
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      isLoading: true,
      errorMessage: null,
    ));

    final result = await _loginUseCase(email: email, password: password);

    result.fold(
      (error) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: error,
        isLoading: false,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      )),
    );
  }

  void clearError() {
    emit(state.clearError());
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
