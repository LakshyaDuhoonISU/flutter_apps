import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class EditBookScreen extends StatefulWidget {
  EditBookScreenState createState() => EditBookScreenState();
}

class EditBookScreenState extends State<EditBookScreen> {
  final idController = TextEditingController();
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final genreController = TextEditingController();
  final priceController = TextEditingController();
  final publishedYearController = TextEditingController();

  void handleSubmit() async {
    Book book = Book(
      id: idController.text,
      title: titleController.text,
      author: authorController.text,
      genre: genreController.text,
      price: priceController.text,
      publishedYear: publishedYearController.text,
    );
    await BookService.updateBook(book);
    Navigator.pop(context);
  }

  Widget build(BuildContext context) {
    Book book = ModalRoute.of(context)!.settings.arguments as Book;
    idController.text = book.id;
    titleController.text = book.title;
    authorController.text = book.author;
    genreController.text = book.genre;
    priceController.text = book.price;
    publishedYearController.text = book.publishedYear;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Book')),
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
              child: Text("Update Book"),
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
