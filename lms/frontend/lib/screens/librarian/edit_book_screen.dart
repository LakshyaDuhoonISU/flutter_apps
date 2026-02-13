import 'package:flutter/material.dart';
import 'package:frontend/models/book.dart';
import 'package:frontend/services/book_service.dart';
import 'package:frontend/utils/custom_alert_box.dart';

class EditBookScreen extends StatefulWidget {
  EditBookScreenState createState() => EditBookScreenState();
}

class EditBookScreenState extends State<EditBookScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final authorController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final imageUrlController = TextEditingController();
  final pdfUrlController = TextEditingController();

  String selectedCategory = 'FYIT';
  String selectedStatus = 'AVAILABLE';
  bool isLoading = false;
  Book? book;

  final List<String> categories = [
    'FYIT',
    'SYIT',
    'TYIT',
    'FYCS',
    'SYCS',
    'TYCS',
  ];

  final List<String> statuses = ['AVAILABLE', 'UNAVAILABLE'];

  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the book passed as argument
    if (book == null) {
      book = ModalRoute.of(context)!.settings.arguments as Book;
      titleController.text = book!.title;
      descriptionController.text = book!.description;
      authorController.text = book!.author;
      priceController.text = book!.price.toString();
      quantityController.text = book!.quantity.toString();
      imageUrlController.text = book!.imageUrl;
      pdfUrlController.text = book!.pdfUrl;
      selectedCategory = book!.category;
      selectedStatus = book!.status;
    }
  }

  void handleUpdateBook() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        authorController.text.isEmpty ||
        priceController.text.isEmpty ||
        quantityController.text.isEmpty ||
        imageUrlController.text.isEmpty ||
        pdfUrlController.text.isEmpty) {
      CustomAlertBox.showError(context, "Error", "Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    Book updatedBook = Book(
      id: book!.id,
      title: titleController.text,
      description: descriptionController.text,
      author: authorController.text,
      price: double.parse(priceController.text),
      quantity: int.parse(quantityController.text),
      imageUrl: imageUrlController.text,
      pdfUrl: pdfUrlController.text,
      category: selectedCategory,
      status: selectedStatus,
    );

    final response = await BookService.updateBook(book!.id, updatedBook);
    setState(() => isLoading = false);

    if (response['message'] == 'Book updated successfully') {
      CustomAlertBox.showSuccess(context, "Success", response['message']);
      Future.delayed(
        Duration(seconds: 1),
        () => Navigator.pushNamed(context, '/librarian_dashboard'),
      );
    } else {
      CustomAlertBox.showError(
        context,
        "Error",
        response['message'] ?? 'Failed to update book',
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Book')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: authorController,
                    decoration: InputDecoration(
                      labelText: 'Author',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCategory = value!);
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedStatus = value!);
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Image URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: pdfUrlController,
                    decoration: InputDecoration(
                      labelText: 'PDF URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: handleUpdateBook,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Update Book',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    authorController.dispose();
    priceController.dispose();
    quantityController.dispose();
    imageUrlController.dispose();
    pdfUrlController.dispose();
    super.dispose();
  }
}
