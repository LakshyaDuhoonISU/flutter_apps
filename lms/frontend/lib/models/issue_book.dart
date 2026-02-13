class IssueBook {
  String id;
  String bookId;
  String bookName;
  String studentId;
  String studentName;
  DateTime issueDate;
  DateTime returnDate;
  String status;

  IssueBook({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.studentId,
    required this.studentName,
    required this.issueDate,
    required this.returnDate,
    required this.status,
  });

  factory IssueBook.fromJson(Map<String, dynamic> json) {
    return IssueBook(
      id: json['_id'] ?? '',
      bookId: json['bookId'] ?? '',
      bookName: json['bookName'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      issueDate: json['issueDate'] != null
          ? DateTime.parse(json['issueDate'])
          : DateTime.now(),
      returnDate: json['returnDate'] != null
          ? DateTime.parse(json['returnDate'])
          : DateTime.now(),
      status: json['status'] ?? 'ISSUED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'bookName': bookName,
      'studentId': studentId,
      'studentName': studentName,
      'issueDate': issueDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'status': status,
    };
  }
}
