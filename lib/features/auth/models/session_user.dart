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
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '-',
      email: json['email'] as String? ?? '-',
      role: json['role'] as String? ?? 'kasir',
      canInputStock: json['can_input_stock'] as bool? ?? false,
      lastLogin: json['last_login'] == null
          ? null
          : DateTime.tryParse('${json['last_login']}'),
    );
  }
}
