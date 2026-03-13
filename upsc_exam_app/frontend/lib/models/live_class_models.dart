class LiveChat {
  final String id;
  final String classId;
  final String userId;
  final String userName;
  final String userRole;
  final String message;
  final bool isDeleted;
  final DateTime createdAt;

  LiveChat({
    required this.id,
    required this.classId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.message,
    required this.isDeleted,
    required this.createdAt,
  });

  factory LiveChat.fromJson(Map<String, dynamic> json) {
    return LiveChat(
      id: json['_id'] ?? '',
      classId: json['classId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userRole: json['userRole'] ?? 'student',
      message: json['message'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class LivePoll {
  final String id;
  final String classId;
  final String question;
  final List<PollOption> options;
  final DateTime endsAt;
  final int durationSeconds;
  final bool isActive;

  LivePoll({
    required this.id,
    required this.classId,
    required this.question,
    required this.options,
    required this.endsAt,
    required this.durationSeconds,
    required this.isActive,
  });

  factory LivePoll.fromJson(Map<String, dynamic> json) {
    return LivePoll(
      id: json['_id'] ?? '',
      classId: json['classId'] ?? '',
      question: json['question'] ?? '',
      options: (json['options'] as List)
          .map((opt) => PollOption.fromJson(opt))
          .toList(),
      endsAt: DateTime.parse(json['endsAt']),
      durationSeconds: json['durationSeconds'] ?? 60,
      isActive: json['isActive'] ?? true,
    );
  }

  LivePoll copyWith({bool? isActive}) {
    return LivePoll(
      id: id,
      classId: classId,
      question: question,
      options: options,
      endsAt: endsAt,
      durationSeconds: durationSeconds,
      isActive: isActive ?? this.isActive,
    );
  }
}

class PollOption {
  final String text;
  final int votes;

  PollOption({required this.text, required this.votes});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(text: json['text'] ?? '', votes: json['votes'] ?? 0);
  }
}

class LiveDoubt {
  final String id;
  final String classId;
  final String studentId;
  final String studentName;
  final String question;
  final String? answer;
  final DateTime? answeredAt;
  final String status;
  final DateTime createdAt;

  LiveDoubt({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.question,
    this.answer,
    this.answeredAt,
    required this.status,
    required this.createdAt,
  });

  factory LiveDoubt.fromJson(Map<String, dynamic> json) {
    return LiveDoubt(
      id: json['_id'] ?? '',
      classId: json['classId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'],
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'])
          : null,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
