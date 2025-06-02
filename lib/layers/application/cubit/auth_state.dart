part of 'auth_cubit.dart';

enum AuthStatus { initial, loading, error, success }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
      ];
}
