import 'package:flutter/material.dart';
import 'package:frontend/models/book.dart';
import 'package:frontend/services/book_service.dart';
import 'package:frontend/utils/custom_alert_box.dart';

class LibrarianBooksScreen extends StatefulWidget {
  LibrarianBooksScreenState createState() => LibrarianBooksScreenState();
}

class LibrarianBooksScreenState extends State<LibrarianBooksScreen> {
  List<Book> books = [];
  List<Book> filteredBooks = [];
  bool isLoading = true;
  String selectedCategory = 'ALL';

  final List<String> categories = [
    'ALL',
    'FYIT',
    'SYIT',
    'TYIT',
    'FYCS',
    'SYCS',
    'TYCS',
  ];

  void initState() {
    super.initState();
    loadBooks();
  }

  void loadBooks() async {
    setState(() => isLoading = true);
    final response = await BookService.getAllBooks();
    if (response['books'] != null) {
      setState(() {
        books = (response['books'] as List)
            .map((book) => Book.fromJson(book))
            .toList();
        filteredBooks = books;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      CustomAlertBox.showError(
        context,
        "Error",
        response['message'] ?? 'Failed to load books',
      );
    }
  }

  void filterBooks(String category) {
    setState(() {
      selectedCategory = category;
      if (category == 'ALL') {
        filteredBooks = books;
      } else {
        filteredBooks = books
            .where((book) => book.category == category)
            .toList();
      }
    });
  }

  void deleteBook(String id) async {
    final response = await BookService.deleteBook(id);
    if (response['message'] == 'Book deleted successfully') {
      CustomAlertBox.showSuccess(context, "Success", response['message']);
      loadBooks();
    } else {
      CustomAlertBox.showError(
        context,
        "Error",
        response['message'] ?? 'Failed to delete book',
      );
    }
  }

  void confirmDelete(String id, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteBook(id);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Books'),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: loadBooks)],
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.map((category) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (selected) => filterBooks(category),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredBooks.isEmpty
                ? Center(child: Text('No books found'))
                : ListView.builder(
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return Card(
                        margin: EdgeInsets.all(8),
                        child: ListTile(
                          leading: book.imageUrl.isNotEmpty
                              ? Image.network(
                                  book.imageUrl,
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.book, size: 50),
                                )
                              : Icon(Icons.book, size: 50),
                          title: Text(
                            book.title,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Author: ${book.author}'),
                              Text('Category: ${book.category}'),
                              Text('Price: \$${book.price}'),
                              Text('Quantity: ${book.quantity}'),
                              Text(
                                'Status: ${book.status}',
                                style: TextStyle(
                                  color: book.status == 'AVAILABLE'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/librarian/edit_book',
                                    arguments: book,
                                  ).then((_) => loadBooks());
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    confirmDelete(book.id, book.title),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/librarian/add_book',
          ).then((_) => loadBooks());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
