// API Service
// Base service for making HTTP requests to the backend

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  // Get stored JWT token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Save JWT token to SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Remove JWT token (used during logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userEmailKey);
    await prefs.remove(userRoleKey);
    await prefs.remove(subscriptionTypeKey);
  }

  // Save user data to SharedPreferences
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, userData['_id'] ?? '');
    await prefs.setString(userNameKey, userData['name'] ?? '');
    await prefs.setString(userEmailKey, userData['email'] ?? '');
    await prefs.setString(userRoleKey, userData['role'] ?? 'student');
    await prefs.setString(
      subscriptionTypeKey,
      userData['subscriptionType'] ?? 'none',
    );
  }

  // Get user data from SharedPreferences
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(userIdKey),
      'name': prefs.getString(userNameKey),
      'email': prefs.getString(userEmailKey),
      'role': prefs.getString(userRoleKey),
      'subscriptionType': prefs.getString(subscriptionTypeKey),
    };
  }

  // GET request
  static Future<http.Response> get(String endpoint) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl$endpoint');

    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  // POST request
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl$endpoint');

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  // PUT request
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl$endpoint');

    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  // DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl$endpoint');

    return await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }
}
