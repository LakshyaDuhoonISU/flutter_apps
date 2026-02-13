import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/utils/get_user_data_from_token.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDashboard extends StatefulWidget {
  StudentDashboardState createState() => StudentDashboardState();
}

class StudentDashboardState extends State<StudentDashboard> {
  User? user;
  bool isLoading = true;

  void loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString('token');
    if (token == null) {
      Navigator.pushNamed(context, '/login');
    }
    setState(() {
      user = getUserDataFromToken(token!);
      isLoading = false;
    });
  }

  void initState() {
    super.initState();
    loadUserData();
  }

  void handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushNamed(context, '/');
  }

  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Student Dashboard")),
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text("Student Dashboard"),
          actions: [
            IconButton(icon: Icon(Icons.logout), onPressed: handleLogout),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, ${user!.name}!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Email: ${user!.email}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              Text(
                "Username: ${user!.username}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(
                      context,
                      "Browse Books",
                      Icons.library_books,
                      Colors.blue,
                      '/student/books',
                    ),
                    _buildDashboardCard(
                      context,
                      "My Profile",
                      Icons.person,
                      Colors.green,
                      '/student/profile',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: color),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
