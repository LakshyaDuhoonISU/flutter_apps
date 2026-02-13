class User {
  String id;
  String username;
  String name;
  String email;
  String password;
  String userType;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.password,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      userType: json['userType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'email': email,
      'password': password,
      'userType': userType,
    };
  }
}
