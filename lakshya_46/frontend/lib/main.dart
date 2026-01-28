import 'package:flutter/material.dart';
import './screens/book_list.dart';
import './screens/add_book.dart';
import './screens/edit_book.dart';
import './screens/view_book.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book CRUD App',
      initialRoute: '/',
      routes: {
        '/': (context) => BookListScreen(),
        '/add_book': (context) => AddBookScreen(),
        '/edit_book': (context) => EditBookScreen(),
        '/view_book': (context) => ViewBookScreen(),
      },
    );
  }
}