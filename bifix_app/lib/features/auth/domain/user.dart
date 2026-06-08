/// A registered user of Vikla.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  User copyWith({String? name, String? email, String? phone}) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}

/// Result of a successful login/register call: a token + the user.
class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final User user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
