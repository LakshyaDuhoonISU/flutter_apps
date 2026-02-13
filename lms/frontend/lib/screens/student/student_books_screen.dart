import 'package:flutter/material.dart';
import 'package:frontend/models/book.dart';
import 'package:frontend/services/book_service.dart';

class StudentBooksScreen extends StatefulWidget {
  StudentBooksScreenState createState() => StudentBooksScreenState();
}

class StudentBooksScreenState extends State<StudentBooksScreen> {
  List<Book> books = [];
  List<Book> filteredBooks = [];
  bool isLoading = true;
  String selectedCategory = 'ALL';
  String searchQuery = '';

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
    }
  }

  void filterBooks() {
    setState(() {
      filteredBooks = books.where((book) {
        bool matchesCategory =
            selectedCategory == 'ALL' || book.category == selectedCategory;
        bool matchesSearch =
            searchQuery.isEmpty ||
            book.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            book.author.toLowerCase().contains(searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void showBookDetails(Book book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(book.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (book.imageUrl.isNotEmpty)
                  Center(
                    child: Image.network(
                      book.imageUrl,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.book, size: 100),
                    ),
                  ),
                SizedBox(height: 16),
                Text(
                  'Author: ${book.author}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Category: ${book.category}'),
                SizedBox(height: 8),
                Text('Price: \$${book.price}'),
                SizedBox(height: 8),
                Text('Available: ${book.quantity}'),
                SizedBox(height: 8),
                Text(
                  'Status: ${book.status}',
                  style: TextStyle(
                    color: book.status == 'AVAILABLE'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(book.description),
                if (book.pdfUrl.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'PDF URL:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    book.pdfUrl,
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Browse Books'),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: loadBooks)],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search by title or author',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                searchQuery = value;
                filterBooks();
              },
            ),
          ),
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
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                        filterBooks();
                      });
                    },
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
                : GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => showBookDetails(book),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: book.imageUrl.isNotEmpty
                                    ? Image.network(
                                        book.imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Center(
                                                  child: Icon(
                                                    Icons.book,
                                                    size: 50,
                                                  ),
                                                ),
                                      )
                                    : Center(child: Icon(Icons.book, size: 50)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      book.author,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '\$${book.price}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Text(
                                          'Qty: ${book.quantity}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: book.quantity > 0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
    );
  }
}
