class Book {
  String id;
  String title;
  String author;
  String genre;
  String price;
  String publishedYear;
  String? createdDate;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.price,
    required this.publishedYear,
    this.createdDate,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      author: json['authorName'] ?? '',
      genre: json['genre'] ?? '',
      price: json['price'] ?? '',
      publishedYear: json['publishedYear'] ?? '',
      createdDate: json['createdDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'authorName': author,
      'genre': genre,
      'price': price,
      'publishedYear': publishedYear,
    };
  }
}
