class AuthService {
  // Simple in-memory current user store (UI-only)
  static Map<String, String>? _currentUser;

  static void setCurrentUser({
    required String id,
    required String username,
    String? name,
    String? email,
    required String role,
  }) {
    _currentUser = {
      'id': id,
      'username': username,
      'name': name ?? '',
      'email': email ?? '',
      'role': role,
    };
  }

  static Map<String, String>? get currentUser => _currentUser;

  static void clear() {
    _currentUser = null;
  }
}
