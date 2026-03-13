// Test Model
// Represents a test/mock exam in the app

class TestModel {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final int totalQuestions;
  final int totalMarks;
  final String courseId;
  final bool isFree;

  TestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.totalMarks,
    required this.courseId,
    required this.isFree,
  });

  // Convert JSON from API to TestModel object
  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      totalMarks: json['totalMarks'] ?? 0,
      courseId: json['courseId'] is Map
          ? json['courseId']['_id'] ?? ''
          : json['courseId'] ?? '',
      isFree: json['isFree'] ?? false,
    );
  }

  // Convert TestModel object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'totalQuestions': totalQuestions,
      'totalMarks': totalMarks,
      'courseId': courseId,
      'isFree': isFree,
    };
  }
}
