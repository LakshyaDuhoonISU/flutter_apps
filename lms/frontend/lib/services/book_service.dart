import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class BookService {
  static String API_URL = 'http://localhost:4000/api/books';

  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>> getAllBooks() async {
    try {
      String? token = await _getToken();
      final response = await http.get(
        Uri.parse(API_URL),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getBookById(String id) async {
    try {
      String? token = await _getToken();
      final response = await http.get(
        Uri.parse('$API_URL/$id'),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addBook(Book book) async {
    try {
      String? token = await _getToken();
      final response = await http.post(
        Uri.parse(API_URL),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
        body: jsonEncode(book.toJson()),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateBook(String id, Book book) async {
    try {
      String? token = await _getToken();
      final response = await http.put(
        Uri.parse('$API_URL/$id'),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
        body: jsonEncode(book.toJson()),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteBook(String id) async {
    try {
      String? token = await _getToken();
      final response = await http.delete(
        Uri.parse('$API_URL/$id'),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }
}
