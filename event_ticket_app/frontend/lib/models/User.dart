// User model - represents a user in the system
class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'user', 'organizer', or 'admin'

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  // Convert JSON from API to User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
    );
  }

  // Convert User object to JSON
  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'role': role};
  }
}
