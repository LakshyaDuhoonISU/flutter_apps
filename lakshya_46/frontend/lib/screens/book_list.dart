import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class BookListScreen extends StatefulWidget {
  BookListScreenState createState() => BookListScreenState();
}

class BookListScreenState extends State<BookListScreen> {
  List<Book> books = [];

  void loadBooks() {
    BookService.getAllBooks().then((value) {
      setState(() {
        books = value;
      });
    });
  }

  void initState() {
    super.initState();
    loadBooks();
  }

  void handleDelete(String id) async {
    await BookService.deleteBook(id);
    loadBooks();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book List')),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          Book book = books[index];
          return ListTile(
            title: Text(book.title),
            subtitle: Text('${book.author} - ${book.genre}'),
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
                        '/view_book',
                        arguments: book,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        '/edit_book',
                        arguments: book,
                      );
                      loadBooks();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      handleDelete(book.id);
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
          await Navigator.pushNamed(context, '/add_book');
          loadBooks();
        },
      ),
    );
  }
}
