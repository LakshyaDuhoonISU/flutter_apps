// Test Result Model
// Represents the result after submitting a test

class TestResult {
  final String id;
  final String userId;
  final dynamic testId; // Can be String or Map when populated
  final List<Answer> answers;
  final int score;
  final int correctCount;
  final int wrongCount;
  final int unattemptedCount;
  final double accuracy;
  final DateTime attemptedAt;

  TestResult({
    required this.id,
    required this.userId,
    required this.testId,
    required this.answers,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.unattemptedCount,
    required this.accuracy,
    required this.attemptedAt,
  });

  // Convert JSON from API to TestResult object
  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['_id'] ?? '',
      userId: json['userId'] is Map
          ? json['userId']['_id'] ?? ''
          : json['userId'] ?? '',
      testId: json['testId'], // Keep as dynamic
      answers: json['answers'] != null
          ? (json['answers'] as List)
                .map((answer) => Answer.fromJson(answer))
                .toList()
          : [],
      score: json['score'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      wrongCount: json['wrongCount'] ?? 0,
      unattemptedCount: json['unattemptedCount'] ?? 0,
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      attemptedAt: json['attemptedAt'] != null
          ? DateTime.parse(json['attemptedAt'])
          : DateTime.now(),
    );
  }

  // Convert TestResult object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'testId': testId is Map ? testId['_id'] : testId,
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'score': score,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'unattemptedCount': unattemptedCount,
      'accuracy': accuracy,
      'attemptedAt': attemptedAt.toIso8601String(),
    };
  }
}

// Answer Model
// Represents a single answer in test result
class Answer {
  final String questionId;
  final int selectedOption; // -1 if unattempted
  final bool isCorrect;

  Answer({
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
  });

  // Convert JSON to Answer object
  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      questionId: json['questionId'] is Map
          ? json['questionId']['_id'] ?? ''
          : json['questionId'] ?? '',
      selectedOption: json['selectedOption'] ?? -1,
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  // Convert Answer object to JSON
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOption': selectedOption,
      'isCorrect': isCorrect,
    };
  }
}
