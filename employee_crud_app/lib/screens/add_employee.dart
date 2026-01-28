import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  AddEmployeeScreenState createState() => AddEmployeeScreenState();
}

class AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final roleController = TextEditingController();
  final departmentController = TextEditingController();
  final salaryController = TextEditingController();

  void handleSubmit() async {
    Employee e = Employee(
      id: "",
      name: nameController.text,
      email: emailController.text,
      role: roleController.text,
      department: departmentController.text,
      salary: salaryController.text,
    );
    await EmployeeService.addEmployee(e);
    Navigator.pop(context);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Employee')),
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
            child: Text("Add Employee"),
            onPressed: () {
              handleSubmit();
            },
          ),
        ],
      ),
    );
  }
}
