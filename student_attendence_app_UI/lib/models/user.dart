enum UserRole { student, teacher, admin }

enum AccountStatus { active, deleted, suspended }

class User {
  final String id;
  final String username;
  final String password; // In real app, this would be hashed
  final UserRole role;
  final String? name;
  final String? email;
  final AccountStatus status;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.name,
    this.email,
    this.status = AccountStatus.active,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  User copyWith({
    String? id,
    String? username,
    String? password,
    UserRole? role,
    String? name,
    String? email,
    AccountStatus? status,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


