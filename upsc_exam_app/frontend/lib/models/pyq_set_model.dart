// PYQSet Model
// Represents a set of Previous Year Questions

class PYQQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String difficulty;
  final int marks;

  PYQQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation = '',
    this.difficulty = 'Medium',
    this.marks = 1,
  });

  factory PYQQuestion.fromJson(Map<String, dynamic> json) {
    return PYQQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      explanation: json['explanation'] ?? '',
      difficulty: json['difficulty'] ?? 'Medium',
      marks: json['marks'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'marks': marks,
    };
  }
}

class PYQSet {
  final String? id;
  final String title;
  final int year;
  final String subject;
  final String description;
  final String courseId;
  final List<PYQQuestion> questions;
  final int totalQuestions;
  final int totalMarks;
  final String? createdBy;
  final DateTime? createdAt;

  PYQSet({
    this.id,
    required this.title,
    required this.year,
    required this.subject,
    this.description = '',
    required this.courseId,
    required this.questions,
    this.totalQuestions = 0,
    this.totalMarks = 0,
    this.createdBy,
    this.createdAt,
  });

  factory PYQSet.fromJson(Map<String, dynamic> json) {
    return PYQSet(
      id: json['_id'],
      title: json['title'] ?? '',
      year: json['year'] ?? 0,
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      courseId: json['courseId'] is String
          ? json['courseId']
          : json['courseId']?['_id'] ?? '',
      questions:
          (json['questions'] as List?)
              ?.map((q) => PYQQuestion.fromJson(q))
              .toList() ??
          [],
      totalQuestions: json['totalQuestions'] ?? 0,
      totalMarks: json['totalMarks'] ?? 0,
      createdBy: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']?['_id'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'year': year,
      'subject': subject,
      'description': description,
      'courseId': courseId,
      'questions': questions.map((q) => q.toJson()).toList(),
      'totalQuestions': totalQuestions,
      'totalMarks': totalMarks,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    };
  }
}
