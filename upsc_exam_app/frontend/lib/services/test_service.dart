// Test Service
// Handles test-related API calls

import 'dart:convert';
import 'api_service.dart';
import '../models/test_model.dart';
import '../models/question_model.dart';
import '../models/test_result_model.dart';

class TestService {
  // Get all tests for a specific course
  static Future<List<TestModel>> getTestsByCourse(String courseId) async {
    try {
      final response = await ApiService.get('/tests/$courseId');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final testsJson = data['data'] as List;
        return testsJson.map((json) => TestModel.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load tests');
      }
    } catch (e) {
      throw Exception('Error loading tests: $e');
    }
  }

  // Get single test with questions
  static Future<Map<String, dynamic>> getTestById(String testId) async {
    try {
      final response = await ApiService.get('/tests/test/$testId');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Parse test and questions
        final testData = data['data'];
        final test = TestModel.fromJson(testData['test']);
        final questionsJson = testData['questions'] as List;
        final questions = questionsJson
            .map((json) => Question.fromJson(json))
            .toList();

        return {'test': test, 'questions': questions};
      } else {
        throw Exception(data['message'] ?? 'Failed to load test');
      }
    } catch (e) {
      throw Exception('Error loading test: $e');
    }
  }

  // Submit test answers
  // answers: Map of questionId -> selectedOption
  static Future<TestResult> submitTest({
    required String testId,
    required Map<String, int> answers,
    required int totalTimeTaken,
  }) async {
    try {
      // Convert answers map to list format expected by backend
      final answersList = answers.entries.map((entry) {
        return {
          'questionId': entry.key,
          'selectedOption': entry.value,
          'timeTaken': 0, // Can be enhanced to track per-question time
        };
      }).toList();

      final response = await ApiService.post('/tests/test/submit', {
        'testId': testId,
        'answers': answersList,
        'totalTimeTaken': totalTimeTaken,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return TestResult.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to submit test');
      }
    } catch (e) {
      throw Exception('Error submitting test: $e');
    }
  }

  // Get test results for a specific test
  static Future<List<TestResult>> getTestResults(String testId) async {
    try {
      final response = await ApiService.get('/tests/test/results/$testId');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final resultsJson = data['data'] as List;
        return resultsJson.map((json) => TestResult.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load results');
      }
    } catch (e) {
      throw Exception('Error loading results: $e');
    }
  }

  // Get all standalone tests
  static Future<List<TestModel>> getAllTests() async {
    try {
      final response = await ApiService.get('/test/all');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final testsJson = data['data'] as List;
        return testsJson.map((json) => TestModel.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load tests');
      }
    } catch (e) {
      throw Exception('Error loading tests: $e');
    }
  }

  // Get educator's tests
  static Future<List<TestModel>> getMyTests() async {
    try {
      final response = await ApiService.get('/test/my-tests');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final testsJson = data['data'] as List;
        return testsJson.map((json) => TestModel.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load tests');
      }
    } catch (e) {
      throw Exception('Error loading tests: $e');
    }
  }

  // Get test by ID with questions
  static Future<Map<String, dynamic>> getTestDetails(String testId) async {
    try {
      final response = await ApiService.get('/test/test/$testId');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final testData = data['data'];
        final test = TestModel.fromJson(testData['test'] ?? testData);

        // Handle questions if they exist
        final questions = testData['questions'] != null
            ? (testData['questions'] as List)
                  .map((json) => Question.fromJson(json))
                  .toList()
            : <Question>[];

        return {'test': test, 'questions': questions};
      } else {
        throw Exception(data['message'] ?? 'Failed to load test');
      }
    } catch (e) {
      throw Exception('Error loading test: $e');
    }
  }

  // Create new test (Educator)
  static Future<TestModel> createTest({
    required String title,
    required String description,
    required int durationMinutes,
    required int totalMarks,
    bool isFree = false,
  }) async {
    try {
      final response = await ApiService.post('/test/create', {
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'totalMarks': totalMarks,
        'isFree': isFree,
        'questions': [], // Empty initially, questions will be added later
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return TestModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to create test');
      }
    } catch (e) {
      throw Exception('Error creating test: $e');
    }
  }

  // Update test (Educator)
  static Future<TestModel> updateTest({
    required String testId,
    String? title,
    String? description,
    int? durationMinutes,
    int? totalMarks,
    bool? isFree,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (durationMinutes != null) body['durationMinutes'] = durationMinutes;
      if (totalMarks != null) body['totalMarks'] = totalMarks;
      if (isFree != null) body['isFree'] = isFree;

      final response = await ApiService.put('/test/$testId', body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return TestModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to update test');
      }
    } catch (e) {
      throw Exception('Error updating test: $e');
    }
  }

  // Delete test (Educator)
  static Future<void> deleteTest(String testId) async {
    try {
      final response = await ApiService.delete('/test/$testId');

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to delete test');
      }
    } catch (e) {
      throw Exception('Error deleting test: $e');
    }
  }

  // Add question to test (Educator)
  static Future<Question> addQuestionToTest({
    required String testId,
    required String question,
    required List<String> options,
    required int correctAnswer,
    String explanation = '',
    String difficulty = 'Medium',
    int marks = 1,
  }) async {
    try {
      final response = await ApiService.post('/test/$testId/question', {
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'difficulty': difficulty,
        'marks': marks,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return Question.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to add question');
      }
    } catch (e) {
      throw Exception('Error adding question: $e');
    }
  }

  // Update question in test (Educator)
  static Future<Question> updateQuestion({
    required String testId,
    required String questionId,
    String? question,
    List<String>? options,
    int? correctAnswer,
    String? explanation,
    String? difficulty,
    int? marks,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (question != null) body['question'] = question;
      if (options != null) body['options'] = options;
      if (correctAnswer != null) body['correctAnswer'] = correctAnswer;
      if (explanation != null) body['explanation'] = explanation;
      if (difficulty != null) body['difficulty'] = difficulty;
      if (marks != null) body['marks'] = marks;

      final response = await ApiService.put(
        '/test/$testId/question/$questionId',
        body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Question.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to update question');
      }
    } catch (e) {
      throw Exception('Error updating question: $e');
    }
  }

  // Delete question from test (Educator)
  static Future<void> deleteQuestion({
    required String testId,
    required String questionId,
  }) async {
    try {
      final response = await ApiService.delete(
        '/test/$testId/question/$questionId',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to delete question');
      }
    } catch (e) {
      throw Exception('Error deleting question: $e');
    }
  }

  // Submit test with answers
  static Future<TestResult> submitTestAttempt({
    required String testId,
    required List<Map<String, dynamic>> answers,
    required int totalTimeTaken,
  }) async {
    try {
      final response = await ApiService.post('/test/submit', {
        'testId': testId,
        'answers': answers,
        'totalTimeTaken': totalTimeTaken,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return TestResult.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to submit test');
      }
    } catch (e) {
      throw Exception('Error submitting test: $e');
    }
  }

  // Get user's test history
  static Future<List<TestResult>> getTestHistory() async {
    try {
      final response = await ApiService.get('/test/history');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final resultsJson = data['data'] as List;
        return resultsJson.map((json) => TestResult.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load test history');
      }
    } catch (e) {
      throw Exception('Error loading test history: $e');
    }
  }

  // Get detailed test result
  static Future<Map<String, dynamic>> getTestResult(String resultId) async {
    try {
      final response = await ApiService.get('/test/result/$resultId');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final resultData = data['data'];
        final result = TestResult.fromJson(resultData);

        // Handle questions with user answers
        final questions = resultData['questions'] != null
            ? (resultData['questions'] as List)
                  .map((json) => Question.fromJson(json))
                  .toList()
            : <Question>[];

        return {'result': result, 'questions': questions};
      } else {
        throw Exception(data['message'] ?? 'Failed to load result');
      }
    } catch (e) {
      throw Exception('Error loading result: $e');
    }
  }
}
