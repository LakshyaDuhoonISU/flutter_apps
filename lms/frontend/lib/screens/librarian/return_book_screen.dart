import 'package:flutter/material.dart';
import 'package:frontend/services/issue_book_service.dart';
import 'package:frontend/utils/custom_alert_box.dart';

class ReturnBookScreen extends StatefulWidget {
  ReturnBookScreenState createState() => ReturnBookScreenState();
}

class ReturnBookScreenState extends State<ReturnBookScreen> {
  final issueIdController = TextEditingController();
  bool isLoading = false;

  void handleReturnBook() async {
    if (issueIdController.text.isEmpty) {
      CustomAlertBox.showError(
        context,
        "Error",
        "Please enter the Issue Book ID",
      );
      return;
    }

    setState(() => isLoading = true);

    final response = await IssueBookService.returnBook(issueIdController.text);
    setState(() => isLoading = false);

    if (response['message'] == 'Book returned successfully') {
      CustomAlertBox.showSuccess(context, "Success", response['message']);
      Future.delayed(Duration(seconds: 1), () {
        issueIdController.clear();
      });
    } else {
      CustomAlertBox.showError(
        context,
        "Error",
        response['message'] ?? 'Failed to return book',
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Return Book')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Instructions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'To return a book, you need the Issue Book ID (MongoDB Object ID) from the database.',
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This ID is generated when a book is issued to a student.',
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: issueIdController,
                    decoration: InputDecoration(
                      labelText: 'Issue Book ID',
                      border: OutlineInputBorder(),
                      hintText: 'Enter the MongoDB Object ID',
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: handleReturnBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Return Book',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Note: The book will be marked as returned and the quantity will be increased in the inventory.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  void dispose() {
    issueIdController.dispose();
    super.dispose();
  }
}
