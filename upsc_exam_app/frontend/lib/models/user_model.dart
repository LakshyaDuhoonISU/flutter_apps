// User Model
// Represents a user (student or educator) in the app

class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' or 'educator'
  final String subscriptionType; // 'plus', 'individual', 'test-series', 'none'
  final List<String> enrolledCourses;
  final int experience; // Years of experience (for educators)

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.subscriptionType,
    required this.enrolledCourses,
    this.experience = 0,
  });

  // Convert JSON from API to User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      subscriptionType: json['subscriptionType'] ?? 'none',
      enrolledCourses: json['enrolledCourses'] != null
          ? List<String>.from(json['enrolledCourses'])
          : [],
      experience: json['experience'] ?? 0,
    );
  }

  // Convert User object to JSON (if needed for API calls)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'subscriptionType': subscriptionType,
      'enrolledCourses': enrolledCourses,
      'experience': experience,
    };
  }
}
