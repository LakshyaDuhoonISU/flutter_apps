import '../models/employee.dart';

class EmployeeService {
  static List<Employee> employees = [];

  static void addEmployee(Employee employee) {
    employees.add(employee);
  }

  static void updateEmployee(Employee employee) {
    int index = employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      employees[index] = employee;
    }
  }

  static void deleteEmployee(int id) {
    employees.removeWhere((e) => e.id == id);
  }

  static List<Employee> getAllEmployees() {
    return employees;
  }

  static Employee getEmployeeById(int id) {
    return employees.firstWhere((e) => e.id == id);
  }
}
