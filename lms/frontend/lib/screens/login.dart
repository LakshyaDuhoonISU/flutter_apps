import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/utils/custom_alert_box.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/get_user_data_from_token.dart';

class LoginScreen extends StatefulWidget {
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  void handleLogin() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      CustomAlertBox.showError(context, "Error", "Please fill in all fields");
      return;
    }

    setState(() => isLoading = true);

    final response = await UserService.login(
      usernameController.text,
      passwordController.text,
    );

    setState(() => isLoading = false);

    if (response['message'] == 'Login successful') {
      String token = response['token'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      User user = getUserDataFromToken(token);
      CustomAlertBox.showSuccess(context, "Success", response['message']);
      Timer(Duration(seconds: 1), () {
        if (user.userType == 'LIBRARIAN') {
          Navigator.pushReplacementNamed(context, '/librarian_dashboard');
        } else if (user.userType == 'STUDENT') {
          Navigator.pushReplacementNamed(context, '/student_dashboard');
        }
      });
    } else {
      CustomAlertBox.showError(context, "Error", response['message']);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.library_books, size: 100, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                "Library Management System",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "Login to your account",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: "Enter your username",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: "Enter your password",
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text("Login", style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? "),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: Text("Register"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
