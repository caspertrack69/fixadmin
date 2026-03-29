import 'session_user.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final SessionUser user;

  AuthSession copyWith({
    String? token,
    SessionUser? user,
  }) {
    return AuthSession(
      token: token ?? this.token,
      user: user ?? this.user,
    );
  }
}
