class Employee {
  String id;
  String name;
  String email;
  String role;
  String department;
  String salary;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.salary,
  });

  factory Employee.fromJson(Map<String, dynamic> map) {
    return Employee(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      salary: map['salary']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'salary': salary,
    };
    if (id.isNotEmpty) {
      json['_id'] = id;
    }
    return json;
  }
}
