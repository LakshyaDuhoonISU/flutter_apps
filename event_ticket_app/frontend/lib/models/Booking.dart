import 'Event.dart';

// Booking model
class Booking {
  final String id;
  final String userId;
  final String eventId;
  final int numberOfTickets;
  final DateTime bookingDate;
  final Event? event; // Optional, populated from backend
  final String? userName; // Optional, populated from backend
  final String? userEmail; // Optional, populated from backend

  Booking({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.numberOfTickets,
    required this.bookingDate,
    this.event,
    this.userName,
    this.userEmail,
  });

  // Convert JSON from API to Booking object
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? '',
      userId: json['user'] is String
          ? json['user']
          : json['user']?['_id'] ?? '',
      eventId: json['event'] is String
          ? json['event']
          : json['event']?['_id'] ?? '',
      numberOfTickets: json['numberOfTickets'] ?? 0,
      bookingDate: DateTime.parse(
        json['bookingDate'],
      ).toLocal(), // Ensure local timezone
      event: json['event'] is Map ? Event.fromJson(json['event']) : null,
      userName: json['user'] is Map ? json['user']['name'] : null,
      userEmail: json['user'] is Map ? json['user']['email'] : null,
    );
  }

  // Calculate total price
  double get totalPrice => (event?.price ?? 0) * numberOfTickets;

  // Convert Booking object to JSON
  Map<String, dynamic> toJson() {
    // Format date without UTC conversion to preserve local time
    final year = bookingDate.year.toString();
    final month = bookingDate.month.toString().padLeft(2, '0');
    final day = bookingDate.day.toString().padLeft(2, '0');
    final hour = bookingDate.hour.toString().padLeft(2, '0');
    final minute = bookingDate.minute.toString().padLeft(2, '0');
    final second = bookingDate.second.toString().padLeft(2, '0');
    final formattedDate = '$year-$month-${day}T$hour:$minute:$second';

    return {
      'user': userId,
      'event': eventId,
      'numberOfTickets': numberOfTickets,
      'bookingDate': formattedDate,
    };
  }
}
