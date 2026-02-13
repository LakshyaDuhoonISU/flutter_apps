import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/utils/custom_alert_box.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  void handleRegister() async {
    if (nameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      CustomAlertBox.showError(context, "Error", "Please fill in all fields");
      return;
    }

    setState(() => isLoading = true);

    User user = User(
      id: '',
      name: nameController.text,
      username: usernameController.text,
      email: emailController.text,
      password: passwordController.text,
      userType: 'STUDENT',
    );

    final response = await UserService.register(user);

    setState(() => isLoading = false);

    if (response['message'] == 'User registered successfully') {
      CustomAlertBox.showSuccess(context, "Success", response['message']);
      Timer(Duration(seconds: 1), () => Navigator.pop(context));
    } else {
      CustomAlertBox.showError(context, "Error", response['message']);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.person_add, size: 80, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                "Create Account",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "Register as a student",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: "Enter your full name",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: "Choose a username",
                  prefixIcon: Icon(Icons.account_circle),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: "Enter your email",
                  prefixIcon: Icon(Icons.email),
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
                  hintText: "Create a password",
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
                onPressed: isLoading ? null : handleRegister,
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
                    : Text("Register", style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? "),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Login"),
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
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
