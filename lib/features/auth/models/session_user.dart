import '../../../core/utils/json_parsers.dart';

class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.canInputStock,
    this.lastLogin,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final bool canInputStock;
  final DateTime? lastLogin;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      email: parseString(json['email']),
      role: parseString(json['role'], fallback: 'kasir'),
      canInputStock: parseBool(json['can_input_stock']),
      lastLogin: parseDateTime(json['last_login']),
    );
  }
}
