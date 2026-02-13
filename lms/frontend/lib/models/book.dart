class Book {
  String id;
  String title;
  String description;
  String author;
  double price;
  int quantity;
  String imageUrl;
  String pdfUrl;
  String category;
  String status;

  Book({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.pdfUrl,
    required this.category,
    required this.status,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      author: json['author'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      pdfUrl: json['pdfUrl'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? 'AVAILABLE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'author': author,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      'category': category,
      'status': status,
    };
  }
}
