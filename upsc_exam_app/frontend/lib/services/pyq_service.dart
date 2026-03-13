// PYQ Service
// Handles Previous Year Question Sets API calls

import 'dart:convert';
import 'api_service.dart';
import '../models/pyq_set_model.dart';

class PyqService {
  // Get all PYQ sets (with optional filters)
  static Future<List<PYQSet>> getAllPYQSets({
    String? courseId,
    int? year,
    String? subject,
  }) async {
    try {
      String endpoint = '/pyq-sets';
      List<String> queryParams = [];

      if (courseId != null) queryParams.add('courseId=$courseId');
      if (year != null) queryParams.add('year=$year');
      if (subject != null) queryParams.add('subject=$subject');

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiService.get(endpoint);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final pyqSetsJson = data['data'] as List;
        return pyqSetsJson.map((json) => PYQSet.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load PYQ sets');
      }
    } catch (e) {
      throw Exception('Error loading PYQ sets: $e');
    }
  }

  // Get PYQ set by ID
  static Future<PYQSet> getPYQSetById(String id) async {
    try {
      final response = await ApiService.get('/pyq-sets/$id');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return PYQSet.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load PYQ set');
      }
    } catch (e) {
      throw Exception('Error loading PYQ set: $e');
    }
  }

  // Create new PYQ set (Educator only)
  static Future<PYQSet> createPYQSet({
    required String title,
    required int year,
    required String subject,
    required String courseId,
    required List<PYQQuestion> questions,
    String description = '',
  }) async {
    try {
      final response = await ApiService.post('/pyq-sets', {
        'title': title,
        'year': year,
        'subject': subject,
        'courseId': courseId,
        'description': description,
        'questions': questions.map((q) => q.toJson()).toList(),
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return PYQSet.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to create PYQ set');
      }
    } catch (e) {
      throw Exception('Error creating PYQ set: $e');
    }
  }

  // Update PYQ set (Educator only)
  static Future<PYQSet> updatePYQSet({
    required String id,
    String? title,
    int? year,
    String? subject,
    String? description,
    List<PYQQuestion>? questions,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (year != null) body['year'] = year;
      if (subject != null) body['subject'] = subject;
      if (description != null) body['description'] = description;
      if (questions != null) {
        body['questions'] = questions.map((q) => q.toJson()).toList();
      }

      final response = await ApiService.put('/pyq-sets/$id', body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return PYQSet.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to update PYQ set');
      }
    } catch (e) {
      throw Exception('Error updating PYQ set: $e');
    }
  }

  // Delete PYQ set (Educator only)
  static Future<void> deletePYQSet(String id) async {
    try {
      final response = await ApiService.delete('/pyq-sets/$id');

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to delete PYQ set');
      }
    } catch (e) {
      throw Exception('Error deleting PYQ set: $e');
    }
  }
}
