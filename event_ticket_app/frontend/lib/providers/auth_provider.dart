import 'package:flutter/material.dart';
import '../models/User.dart';
import '../service/api_service.dart';

// Auth Provider - manages authentication state
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser; // _ means variable is private, so we expose it via a getter
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // Check if user is already logged in (on app start)
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _apiService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  // Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );

    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Login user
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.login(email: email, password: password);

    _isLoading = false;

    if (result['success']) {
      _currentUser = result['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
