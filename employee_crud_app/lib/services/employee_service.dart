import '../models/employee.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmployeeService {
  static String API_URL = 'http://localhost:4000/employees/';

  static Future<void> addEmployee(Employee employee) async {
    await http.post(
      Uri.parse(API_URL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(employee.toJson()),
    );
  }

  static Future<void> updateEmployee(Employee employee) async {
    await http.put(
      Uri.parse('${API_URL}${employee.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(employee.toJson()),
    );
  }

  static Future<void> deleteEmployee(String id) async {
    final response = await http.delete(Uri.parse('$API_URL$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete employee: ${response.statusCode}');
    }
  }

  static Future<List<Employee>> getAllEmployees() async {
    final response = await http.get(Uri.parse(API_URL));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Employee.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load employees');
    }
  }

  static Future<Employee> getEmployeeById(String id) async {
    final response = await http.get(Uri.parse('$API_URL$id'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Employee.fromJson(data);
    } else {
      throw Exception('Failed to load employee');
    }
  }
}
