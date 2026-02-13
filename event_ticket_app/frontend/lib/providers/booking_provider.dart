import 'package:flutter/material.dart';
import '../models/Booking.dart';
import '../service/api_service.dart';

// Booking Provider - manages bookings state
class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch user's bookings
  Future<void> fetchMyBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookings = await _apiService.getMyBookings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new booking
  Future<bool> createBooking({
    required String eventId,
    required int numberOfTickets,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.createBooking(
      eventId: eventId,
      numberOfTickets: numberOfTickets,
    );

    _isLoading = false;

    if (result['success']) {
      // Refresh bookings list
      await fetchMyBookings();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
