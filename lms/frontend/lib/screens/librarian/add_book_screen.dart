import 'package:flutter/material.dart';
import 'package:frontend/models/book.dart';
import 'package:frontend/services/book_service.dart';
import 'package:frontend/utils/custom_alert_box.dart';

class AddBookScreen extends StatefulWidget {
  AddBookScreenState createState() => AddBookScreenState();
}

class AddBookScreenState extends State<AddBookScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final authorController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final imageUrlController = TextEditingController();
  final pdfUrlController = TextEditingController();

  String selectedCategory = 'FYIT';
  bool isLoading = false;

  final List<String> categories = [
    'FYIT',
    'SYIT',
    'TYIT',
    'FYCS',
    'SYCS',
    'TYCS',
  ];

  void handleAddBook() async {
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

    Book newBook = Book(
      id: '',
      title: titleController.text,
      description: descriptionController.text,
      author: authorController.text,
      price: double.parse(priceController.text),
      quantity: int.parse(quantityController.text),
      imageUrl: imageUrlController.text,
      pdfUrl: pdfUrlController.text,
      category: selectedCategory,
      status: 'AVAILABLE',
    );

    final response = await BookService.addBook(newBook);
    setState(() => isLoading = false);

    if (response['message'] == 'Book added successfully') {
      CustomAlertBox.showSuccess(context, "Success", response['message']);
      Future.delayed(
        Duration(seconds: 1),
        () => Navigator.pushNamed(context, '/librarian_dashboard'),
      );
    } else {
      CustomAlertBox.showError(
        context,
        "Error",
        response['message'] ?? 'Failed to add book',
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Book')),
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
                    onPressed: handleAddBook,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Add Book', style: TextStyle(fontSize: 18)),
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
