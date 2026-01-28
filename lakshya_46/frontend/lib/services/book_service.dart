import '../models/book.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookService {
  static String API_URL = 'http://localhost:4000/books/';

  static Future<void> addBook(Book book) async {
    await http.post(
      Uri.parse(API_URL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(book.toJson()),
    );
  }

  static Future<void> updateBook(Book book) async {
    await http.put(
      Uri.parse('${API_URL}${book.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(book.toJson()),
    );
  }

  static Future<void> deleteBook(String id) async {
    final response = await http.delete(Uri.parse('$API_URL$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete book: ${response.statusCode}');
    }
  }

  static Future<List<Book>> getAllBooks() async {
    final response = await http.get(Uri.parse(API_URL));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Book.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }

  static Future<Book> getBookById(String id) async {
    final response = await http.get(Uri.parse('$API_URL$id'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Book.fromJson(data);
    } else {
      throw Exception('Failed to load book');
    }
  }
}
