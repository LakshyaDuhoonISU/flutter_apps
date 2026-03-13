// Course Model
// Represents a course in the UPSC preparation app

class Course {
  final String id;
  final String title;
  final String subject;
  final String description;
  final String educatorId;
  final String? educatorName; // Populated from API
  final double price;
  final bool isPlusIncluded;
  final int enrolledStudents;
  final String? thumbnail;

  Course({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.educatorId,
    this.educatorName,
    required this.price,
    required this.isPlusIncluded,
    required this.enrolledStudents,
    this.thumbnail,
  });

  // Convert JSON from API to Course object
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      educatorId: json['educatorId'] is Map
          ? json['educatorId']['_id'] ?? ''
          : json['educatorId'] ?? '',
      educatorName: json['educatorId'] is Map
          ? json['educatorId']['name']
          : null,
      price: (json['price'] ?? 0).toDouble(),
      isPlusIncluded: json['isPlusIncluded'] ?? false,
      enrolledStudents: json['enrolledStudents'] ?? 0,
      thumbnail: json['thumbnail'],
    );
  }

  // Convert Course object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'subject': subject,
      'description': description,
      'educatorId': educatorId,
      'price': price,
      'isPlusIncluded': isPlusIncluded,
      'enrolledStudents': enrolledStudents,
      'thumbnail': thumbnail,
    };
  }
}
