import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';

class EditEmployeeScreen extends StatefulWidget {
  EditEmployeeScreenState createState() => EditEmployeeScreenState();
}

class EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final idController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final roleController = TextEditingController();
  final departmentController = TextEditingController();
  final salaryController = TextEditingController();

  void handleSubmit() async {
    Employee e = Employee(
      id: idController.text,
      name: nameController.text,
      email: emailController.text,
      role: roleController.text,
      department: departmentController.text,
      salary: salaryController.text,
    );
    await EmployeeService.updateEmployee(e);
    Navigator.pop(context);
  }

  Widget build(BuildContext context) {
    Employee employee = ModalRoute.of(context)!.settings.arguments as Employee;
    idController.text = employee.id;
    nameController.text = employee.name;
    emailController.text = employee.email;
    roleController.text = employee.role;
    departmentController.text = employee.department;
    salaryController.text = employee.salary;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Employee')),
      body: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: roleController,
            decoration: InputDecoration(labelText: 'Role'),
          ),
          TextField(
            controller: departmentController,
            decoration: InputDecoration(labelText: 'Department'),
          ),
          TextField(
            controller: salaryController,
            decoration: InputDecoration(labelText: 'Salary'),
          ),
          TextButton(
            child: Text("Update Employee"),
            onPressed: () {
              handleSubmit();
            },
          ),
        ],
      ),
    );
  }
}
