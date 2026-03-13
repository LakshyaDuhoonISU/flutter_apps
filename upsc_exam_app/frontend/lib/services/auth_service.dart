// Auth Service
// Handles authentication-related API calls (login, register, logout)

import 'dart:convert';
import 'api_service.dart';
import 'socket_service.dart';
import '../models/user_model.dart';

class AuthService {
  // Register a new user
  // Returns User object if successful, throws exception if failed
  static Future<User> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Registration successful
        final token = data['data']['token'];
        await ApiService.saveToken(token);
        await ApiService.saveUserData(data['data']);

        return User.fromJson(data['data']);
      } else {
        // Registration failed
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Error during registration: $e');
    }
  }

  // Login user
  // Returns User object if successful, throws exception if failed
  static Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Login successful
        final token = data['data']['token'];
        await ApiService.saveToken(token);
        await ApiService.saveUserData(data['data']);

        return User.fromJson(data['data']);
      } else {
        // Login failed
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  // Get current logged in user
  static Future<User> getCurrentUser() async {
    try {
      final response = await ApiService.get('/auth/me');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return User.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to get user');
      }
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  // Logout user
  static Future<void> logout() async {
    // Disconnect socket before clearing token so the backend sees a proper disconnect
    SocketService.disconnect();
    await ApiService.removeToken();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }

  // Upgrade user subscription
  static Future<User> upgradeSubscription(String subscriptionType) async {
    try {
      final response = await ApiService.put('/auth/upgrade', {
        'subscriptionType': subscriptionType,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Subscription upgraded successfully
        await ApiService.saveUserData(data['data']);
        return User.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Upgrade failed');
      }
    } catch (e) {
      throw Exception('Error upgrading subscription: $e');
    }
  }

  // Update user profile
  static Future<User> updateProfile({String? name, int? experience}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (experience != null) body['experience'] = experience;

      final response = await ApiService.put('/auth/profile', body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Profile updated successfully
        await ApiService.saveUserData(data['data']);
        return User.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Profile update failed');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Get educator statistics
  static Future<Map<String, dynamic>> getEducatorStats() async {
    try {
      final response = await ApiService.get('/auth/educator-stats');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to get stats');
      }
    } catch (e) {
      throw Exception('Error getting educator stats: $e');
    }
  }
}
