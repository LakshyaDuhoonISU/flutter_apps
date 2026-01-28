import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';

class EmployeeListScreen extends StatefulWidget {
  EmployeeListScreenState createState() => EmployeeListScreenState();
}

class EmployeeListScreenState extends State<EmployeeListScreen> {
  List<Employee> employees = [];

  void loadEmployees() {
    EmployeeService.getAllEmployees().then((value) {
      setState(() {
        employees = value;
      });
    });
  }

  void initState() {
    super.initState();
    loadEmployees();
  }

  void handleDelete(String id) async {
      await EmployeeService.deleteEmployee(id);
      loadEmployees();
    }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Employee List')),
      body: ListView.builder(
        itemCount: employees.length,
        itemBuilder: (context, index) {
          Employee employee = employees[index];
          return ListTile(
            title: Text(employee.name),
            subtitle: Text(employee.email),
            trailing: SizedBox(
              width: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.visibility),
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        '/view_employee',
                        arguments: Employee(
                          id: employee.id,
                          name: employee.name,
                          email: employee.email,
                          role: employee.role,
                          department: employee.department,
                          salary: employee.salary,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        '/edit_employee',
                        arguments: Employee(
                          id: employee.id,
                          name: employee.name,
                          email: employee.email,
                          role: employee.role,
                          department: employee.department,
                          salary: employee.salary,
                        ),
                      );
                      loadEmployees();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      handleDelete(employee.id);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.pushNamed(context, '/add_employee');
          loadEmployees();
        },
      ),
    );
  }
}
