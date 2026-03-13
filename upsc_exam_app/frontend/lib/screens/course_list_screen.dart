// Course List Screen
// Displays all available courses

import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({Key? key}) : super(key: key);

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  // Future to fetch courses
  late Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = CourseService.getAllCourses();
  }

  // Refresh courses
  Future<void> _refreshCourses() async {
    setState(() {
      _coursesFuture = CourseService.getAllCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Courses'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _refreshCourses,
        child: FutureBuilder<List<Course>>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshCourses,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Success state
            final courses = snapshot.data!;

            // No courses found
            if (courses.isEmpty) {
              return const Center(
                child: Text(
                  'No courses available',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            // Display courses in a list
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return CourseCard(
                  course: course,
                  onTap: () {
                    // Navigate to course detail screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            CourseDetailScreen(courseId: course.id),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
