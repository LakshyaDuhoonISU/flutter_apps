// Event model - represents an event
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String imageUrl;
  final String location;
  final int totalTickets;
  final int? availableTickets; // Optional - only sent from backend
  final double price;
  final String organizerId;
  final String? organizerName; // Optional, populated from backend
  final String? organizerEmail; // Optional, populated from backend

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    required this.location,
    required this.totalTickets,
    this.availableTickets,
    required this.price,
    required this.organizerId,
    this.organizerName,
    this.organizerEmail,
  });

  // Convert JSON from API to Event object
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']).toLocal(), // Ensure local timezone
      imageUrl: json['imageUrl'] ?? '',
      location: json['location'] ?? '',
      totalTickets: json['totalTickets'] ?? 0,
      availableTickets: json['availableTickets'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      organizerId: json['organizer'] is String
          ? json['organizer']
          : json['organizer']?['_id'] ?? '',
      organizerName: json['organizer'] is Map
          ? json['organizer']['name']
          : null,
      organizerEmail: json['organizer'] is Map
          ? json['organizer']['email']
          : null,
    );
  }

  // Convert Event object to JSON
  Map<String, dynamic> toJson() {
    // Format date without UTC conversion to preserve local time
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    final formattedDate = '$year-$month-${day}T$hour:$minute:$second';

    return {
      'title': title,
      'description': description,
      'date': formattedDate,
      'imageUrl': imageUrl,
      'location': location,
      'totalTickets': totalTickets,
      'price': price,
    };
  }

  // Calculate tickets sold
  int get ticketsSold => totalTickets - (availableTickets ?? totalTickets);
}
