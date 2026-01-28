import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class AddBookScreen extends StatefulWidget {
  AddBookScreenState createState() => AddBookScreenState();
}

class AddBookScreenState extends State<AddBookScreen> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final genreController = TextEditingController();
  final priceController = TextEditingController();
  final publishedYearController = TextEditingController();

  void handleSubmit() async {
    Book book = Book(
      id: "",
      title: titleController.text,
      author: authorController.text,
      genre: genreController.text,
      price: priceController.text,
      publishedYear: publishedYearController.text,
    );
    await BookService.addBook(book);
    Navigator.pop(context);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Book')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: authorController,
              decoration: InputDecoration(labelText: 'Author Name'),
            ),
            TextField(
              controller: genreController,
              decoration: InputDecoration(labelText: 'Genre'),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Price'),
            ),
            TextField(
              controller: publishedYearController,
              decoration: InputDecoration(labelText: 'Published Year'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("Add Book"),
              onPressed: () {
                handleSubmit();
              },
            ),
          ],
        ),
      ),
    );
  }
}
