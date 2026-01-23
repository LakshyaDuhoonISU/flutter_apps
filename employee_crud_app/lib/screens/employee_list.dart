import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';

class EmployeeListScreen extends StatefulWidget {
  EmployeeListScreenState createState() => EmployeeListScreenState();
}

class EmployeeListScreenState extends State<EmployeeListScreen> {
  List<Employee> employees = [];

  void initState() {
    super.initState();
    setState(() {
      employees = EmployeeService.getAllEmployees();
    });
  }

  void handleDelete(int id) {
    EmployeeService.deleteEmployee(id);
    setState(() {
      employees = EmployeeService.getAllEmployees();
    });
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
                  IconButton(icon: Icon(Icons.visibility), onPressed: () {}),
                  IconButton(icon: Icon(Icons.edit), onPressed: () {}),
                  IconButton(icon: Icon(Icons.delete), onPressed: () {
                    handleDelete(employee.id);
                  }),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/add_employee').then((_) {
            setState(() {
              employees = EmployeeService.getAllEmployees();
            }); 
          });
        },
      ),
    );
  }
}
