// Course Service
// Handles course-related API calls

import 'dart:convert';
import 'api_service.dart';
import '../models/course_model.dart';

class CourseService {
  // Get all courses
  // Returns list of Course objects
  static Future<List<Course>> getAllCourses() async {
    try {
      final response = await ApiService.get('/courses');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final coursesJson = data['data'] as List;
        return coursesJson.map((json) => Course.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load courses');
      }
    } catch (e) {
      throw Exception('Error loading courses: $e');
    }
  }

  // Get single course by ID
  static Future<Map<String, dynamic>> getCourseById(String courseId) async {
    try {
      final response = await ApiService.get('/courses/$courseId');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load course');
      }
    } catch (e) {
      throw Exception('Error loading course: $e');
    }
  }

  // Get enrolled courses for current user
  static Future<List<Course>> getEnrolledCourses() async {
    try {
      final response = await ApiService.get('/courses/my-courses');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final coursesJson = data['data'] as List;
        return coursesJson.map((json) => Course.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load enrolled courses');
      }
    } catch (e) {
      throw Exception('Error loading enrolled courses: $e');
    }
  }

  // Get class schedule for enrolled courses
  static Future<List<dynamic>> getMySchedule() async {
    try {
      final response = await ApiService.get('/courses/my-schedule');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'] as List;
      } else {
        throw Exception(data['message'] ?? 'Failed to load schedule');
      }
    } catch (e) {
      throw Exception('Error loading schedule: $e');
    }
  }

  // Enroll in a course
  static Future<void> enrollInCourse(String courseId) async {
    try {
      final response = await ApiService.post('/courses/$courseId/enroll', {});

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw data['message'] ?? 'Failed to enroll in course';
      }
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Error enrolling in course: $e';
    }
  }

  // Mark class as completed
  static Future<void> markClassCompleted(String classId) async {
    try {
      final response = await ApiService.post(
        '/courses/classes/$classId/complete',
        {},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to mark class as completed');
      }
    } catch (e) {
      throw Exception('Error marking class as completed: $e');
    }
  }

  // Bookmark a class
  static Future<void> bookmarkClass(String classId) async {
    try {
      final response = await ApiService.post(
        '/courses/classes/$classId/bookmark',
        {},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to bookmark class');
      }
    } catch (e) {
      throw Exception('Error bookmarking class: $e');
    }
  }

  // Remove bookmark from a class
  static Future<void> unbookmarkClass(String classId) async {
    try {
      final response = await ApiService.delete(
        '/courses/classes/$classId/bookmark',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to remove bookmark');
      }
    } catch (e) {
      throw Exception('Error removing bookmark: $e');
    }
  }

  // Get all bookmarked classes
  static Future<List<Map<String, dynamic>>> getBookmarkedClasses() async {
    try {
      final response = await ApiService.get('/courses/bookmarks');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(
          data['message'] ?? 'Failed to fetch bookmarked classes',
        );
      }
    } catch (e) {
      throw Exception('Error fetching bookmarked classes: $e');
    }
  }

  // Get notes for a class
  static Future<List<Map<String, dynamic>>> getClassNotes(
    String classId,
  ) async {
    try {
      final response = await ApiService.get('/courses/classes/$classId/notes');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch notes');
      }
    } catch (e) {
      throw Exception('Error fetching notes: $e');
    }
  }

  // Add a note to a class
  static Future<Map<String, dynamic>> addClassNote(
    String classId,
    String content, {
    bool isHighlighted = false,
  }) async {
    try {
      final response = await ApiService.post(
        '/courses/classes/$classId/notes',
        {'content': content, 'isHighlighted': isHighlighted},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to add note');
      }
    } catch (e) {
      throw Exception('Error adding note: $e');
    }
  }

  // Update a note
  static Future<Map<String, dynamic>> updateClassNote(
    String classId,
    String noteId,
    String content, {
    bool? isHighlighted,
  }) async {
    try {
      final body = {
        'content': content,
        if (isHighlighted != null) 'isHighlighted': isHighlighted,
      };

      final response = await ApiService.put(
        '/courses/classes/$classId/notes/$noteId',
        body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to update note');
      }
    } catch (e) {
      throw Exception('Error updating note: $e');
    }
  }

  // Delete a note
  static Future<void> deleteClassNote(String classId, String noteId) async {
    try {
      final response = await ApiService.delete(
        '/courses/classes/$classId/notes/$noteId',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to delete note');
      }
    } catch (e) {
      throw Exception('Error deleting note: $e');
    }
  }
}
