import 'package:flutter/material.dart';
import '../models/employee.dart';

class ViewEmployee extends StatelessWidget{

  Widget build(BuildContext context) {
    
    Employee employee=ModalRoute.of(context)!.settings.arguments as Employee;

    return Scaffold(
      appBar: AppBar(
        title: Text('View Employee')
      ),
      body: Center(
        child: Column(
          children: [
            Text('Name: ${employee.name}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Email: ${employee.email}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Role: ${employee.role}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Department: ${employee.department}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Salary: ${employee.salary}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]
        )
      )
    );
  }
}