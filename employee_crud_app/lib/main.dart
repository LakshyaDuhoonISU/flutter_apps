import 'package:flutter/material.dart';
import 'screens/employee_list.dart';
import 'screens/add_employee.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee CRUD App',
      initialRoute: '/',
      routes: {
        '/': (context) => EmployeeListScreen(),
        '/add_employee': (context) => AddEmployeeScreen(),
      },
    );
  }
}
