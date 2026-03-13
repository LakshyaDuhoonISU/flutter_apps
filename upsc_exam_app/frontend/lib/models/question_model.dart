// Question Model
// Represents a single question in a test

class Question {
  final String id;
  final String testId;
  final String question;
  final List<String> options;
  final int? correctAnswer; // Only available after test submission
  final String? explanation; // Only available after test submission
  final String difficulty;
  final int marks;
  final bool isPreviousYear;
  final int? year;

  Question({
    required this.id,
    required this.testId,
    required this.question,
    required this.options,
    this.correctAnswer,
    this.explanation,
    required this.difficulty,
    required this.marks,
    this.isPreviousYear = false,
    this.year,
  });

  // Convert JSON from API to Question object
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? '',
      testId: json['testId'] is Map
          ? json['testId']['_id'] ?? ''
          : json['testId'] ?? '',
      question: json['question'] ?? '',
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : [],
      correctAnswer: json['correctAnswer'] != null
          ? (json['correctAnswer'] as num).toInt()
          : null,
      explanation: json['explanation'],
      difficulty: json['difficulty'] ?? 'Medium',
      marks: json['marks'] != null ? (json['marks'] as num).toInt() : 1,
      isPreviousYear: json['isPreviousYear'] ?? false,
      year: json['year'] != null ? (json['year'] as num).toInt() : null,
    );
  }

  // Convert Question object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'testId': testId,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'marks': marks,
      'isPreviousYear': isPreviousYear,
      'year': year,
    };
  }
}
