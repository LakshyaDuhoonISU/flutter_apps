import 'package:flutter/material.dart';
import 'package:frontend/models/book.dart';
import 'package:frontend/models/issue_book.dart';
import 'package:frontend/services/book_service.dart';
import 'package:frontend/services/issue_book_service.dart';
import 'package:frontend/utils/custom_alert_box.dart';

class IssueBookScreen extends StatefulWidget {
  IssueBookScreenState createState() => IssueBookScreenState();
}

class IssueBookScreenState extends State<IssueBookScreen> {
  final studentIdController = TextEditingController();
  final studentNameController = TextEditingController();
  final returnDateController = TextEditingController();

  List<Book> books = [];
  Book? selectedBook;
  bool isLoading = false;
  DateTime? selectedReturnDate;

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
            .where((book) => book.quantity > 0 && book.status == 'AVAILABLE')
            .toList();
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

  Future<void> selectReturnDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedReturnDate = picked;
        returnDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void handleIssueBook() async {
    if (selectedBook == null ||
        studentIdController.text.isEmpty ||
        studentNameController.text.isEmpty ||
        selectedReturnDate == null) {
      CustomAlertBox.showError(context, "Error", "Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    IssueBook issueBook = IssueBook(
      id: '',
      bookId: selectedBook!.id,
      bookName: selectedBook!.title,
      studentId: studentIdController.text,
      studentName: studentNameController.text,
      issueDate: DateTime.now(),
      returnDate: selectedReturnDate!,
      status: 'ISSUED',
    );

    final response = await IssueBookService.issueBook(issueBook);
    setState(() => isLoading = false);

    if (response['message'] == 'Book issued successfully') {
      CustomAlertBox.showSuccess(context, "Success", response['message']);
      Future.delayed(Duration(seconds: 1), () {
        studentIdController.clear();
        studentNameController.clear();
        returnDateController.clear();
        setState(() {
          selectedBook = null;
          selectedReturnDate = null;
        });
        loadBooks();
      });
    } else {
      CustomAlertBox.showError(
        context,
        "Error",
        response['message'] ?? 'Failed to issue book',
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Issue Book')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select Book',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<Book>(
                    value: selectedBook,
                    decoration: InputDecoration(
                      labelText: 'Book',
                      border: OutlineInputBorder(),
                    ),
                    items: books.map((book) {
                      return DropdownMenuItem(
                        value: book,
                        child: Text('${book.title} (Qty: ${book.quantity})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedBook = value);
                    },
                  ),
                  if (selectedBook != null) ...[
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedBook!.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('Author: ${selectedBook!.author}'),
                            Text('Category: ${selectedBook!.category}'),
                            Text('Available: ${selectedBook!.quantity}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 24),
                  Text(
                    'Student Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: studentIdController,
                    decoration: InputDecoration(
                      labelText: 'Student ID',
                      border: OutlineInputBorder(),
                      hintText: 'Enter MongoDB Object ID',
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: studentNameController,
                    decoration: InputDecoration(
                      labelText: 'Student Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: returnDateController,
                    decoration: InputDecoration(
                      labelText: 'Return Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => selectReturnDate(context),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: handleIssueBook,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Issue Book', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void dispose() {
    studentIdController.dispose();
    studentNameController.dispose();
    returnDateController.dispose();
    super.dispose();
  }
}
