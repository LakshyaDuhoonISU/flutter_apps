import 'package:flutter/material.dart';
import 'package:frontend/screens/librarian/add_book_screen.dart';
import 'package:frontend/screens/librarian/edit_book_screen.dart';
import 'package:frontend/screens/librarian/issue_book_screen.dart';
import 'package:frontend/screens/librarian/librarian_books_screen.dart';
import 'package:frontend/screens/librarian/librarian_dashboard.dart';
import 'package:frontend/screens/librarian/return_book_screen.dart';
import 'package:frontend/screens/login.dart';
import 'package:frontend/screens/register.dart';
import 'package:frontend/screens/student/student_books_screen.dart';
import 'package:frontend/screens/student/student_dashboard.dart';
import 'package:frontend/screens/student/student_profile_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMS',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/librarian_dashboard': (context) => LibrarianDashboard(),
        '/student_dashboard': (context) => StudentDashboard(),
        '/librarian/books': (context) => LibrarianBooksScreen(),
        '/librarian/add_book': (context) => AddBookScreen(),
        '/librarian/edit_book': (context) => EditBookScreen(),
        '/librarian/issue_book': (context) => IssueBookScreen(),
        '/librarian/return_book': (context) => ReturnBookScreen(),
        '/student/books': (context) => StudentBooksScreen(),
        '/student/profile': (context) => StudentProfileScreen(),
      },
    );
  }
}
