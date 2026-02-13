import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/User.dart';
import '../models/Event.dart';
import '../models/Booking.dart';

// API Service - handles all HTTP requests to the backend
class ApiService {
  
  static const String baseUrl = 'http://localhost:3000/api';

  // Get stored JWT token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Save JWT token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Get headers with authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============== AUTH APIs ==============

  // Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token
        await _saveToken(data['token']);

        // Save user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));

        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // Get current user from storage
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // ============== EVENT APIs ==============

  // Get all events (public)
  Future<List<Event>> getAllEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/events'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List events = data['events'];
        return events.map((e) => Event.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get organizer's events only
  Future<List<Event>> getMyEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/events/my-events'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List events = data['events'];
        return events.map((e) => Event.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get single event by ID
  Future<Event> getEventById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/events/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Event.fromJson(data['event']);
      } else {
        throw Exception('Failed to load event');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Create new event (organizer only)
  Future<Map<String, dynamic>> createEvent(Event event) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: headers,
        body: jsonEncode(event.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'event': Event.fromJson(data['event'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create event',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update event (organizer only)
  Future<Map<String, dynamic>> updateEvent(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/events/$id'),
        headers: headers,
        body: jsonEncode(updates),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'event': Event.fromJson(data['event'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update event',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete event (organizer only)
  Future<Map<String, dynamic>> deleteEvent(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete event',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ============== BOOKING APIs ==============

  // Create booking (user only)
  Future<Map<String, dynamic>> createBooking({
    required String eventId,
    required int numberOfTickets,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
        body: jsonEncode({
          'eventId': eventId,
          'numberOfTickets': numberOfTickets,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'booking': Booking.fromJson(data['booking'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Booking failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get user's bookings
  Future<List<Booking>> getMyBookings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/my'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List bookings = data['bookings'];
        return bookings.map((b) => Booking.fromJson(b)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get bookings for a specific event (organizer only)
  Future<Map<String, dynamic>> getEventBookings(String eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/event/$eventId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List bookings = data['bookings'];
        return {
          'bookings': bookings.map((b) => Booking.fromJson(b)).toList(),
          'totalTicketsSold': data['totalTicketsSold'],
          'totalRevenue': data['totalRevenue'],
        };
      } else {
        throw Exception('Failed to load event bookings');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ============== ADMIN APIs ==============

  // Get all events (admin)
  Future<List<Event>> getAdminEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/events'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List events = data['events'];
        return events.map((e) => Event.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get all bookings (admin)
  Future<List<Booking>> getAdminBookings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/bookings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List bookings = data['bookings'];
        return bookings.map((b) => Booking.fromJson(b)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get analytics stats (admin)
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analytics'];
      } else {
        throw Exception('Failed to load stats');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Update any event (admin)
  Future<Map<String, dynamic>> adminUpdateEvent(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/events/$id'),
        headers: headers,
        body: jsonEncode(updates),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'event': Event.fromJson(data['event'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update event',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete any event (admin)
  Future<Map<String, dynamic>> adminDeleteEvent(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/events/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete event',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
