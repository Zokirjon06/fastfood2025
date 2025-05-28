import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;

  const UserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.emailVerified,
  });

  @override
  List<Object?> get props => [uid, email, displayName, photoURL, emailVerified];

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
