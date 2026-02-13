import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/issue_book.dart';

class IssueBookService {
  static String API_URL = 'http://localhost:4000/api/issue';

  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>> issueBook(IssueBook issueBook) async {
    try {
      String? token = await _getToken();
      final response = await http.post(
        Uri.parse('$API_URL/issue-book'),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
        body: jsonEncode(issueBook.toJson()),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> returnBook(String id) async {
    try {
      String? token = await _getToken();
      final response = await http.post(
        Uri.parse('$API_URL/return-book/$id'),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }
}
