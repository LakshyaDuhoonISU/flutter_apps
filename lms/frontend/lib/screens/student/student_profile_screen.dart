import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/utils/get_user_data_from_token.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfileScreen extends StatefulWidget {
  StudentProfileScreenState createState() => StudentProfileScreenState();
}

class StudentProfileScreenState extends State<StudentProfileScreen> {
  User? user;
  bool isLoading = true;

  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString('token');
    if (token == null) {
      Navigator.pushNamed(context, '/');
      return;
    }
    setState(() {
      user = getUserDataFromToken(token);
      isLoading = false;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 24),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    user!.name,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Chip(
                    label: Text(user!.userType),
                    backgroundColor: Colors.blue.shade100,
                  ),
                  SizedBox(height: 32),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(),
                          SizedBox(height: 16),
                          _buildInfoRow(Icons.badge, 'User ID', user!.id),
                          SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.person_outline,
                            'Username',
                            user!.username,
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow(Icons.email, 'Email', user!.email),
                          SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.account_circle,
                            'Account Type',
                            user!.userType,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 40,
                            color: Colors.blue.shade700,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Library Member',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You can browse available books and request book issues from the librarian.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade700),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
