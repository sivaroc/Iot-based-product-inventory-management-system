class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final DateTime lastLogin;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.lastLogin,
  });
}