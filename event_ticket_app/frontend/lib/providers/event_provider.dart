import 'package:flutter/material.dart';
import '../models/Event.dart';
import '../service/api_service.dart';

// Event Provider - manages events state
class EventProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch all events (public)
  Future<void> fetchAllEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _apiService.getAllEvents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch organizer's events only
  Future<void> fetchMyEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _apiService.getMyEvents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new event
  Future<bool> createEvent(Event event) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.createEvent(event);
    _isLoading = false;

    if (result['success']) {
      // Refresh events list
      await fetchMyEvents();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Update event
  Future<bool> updateEvent(String id, Map<String, dynamic> updates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.updateEvent(id, updates);
    _isLoading = false;

    if (result['success']) {
      // Refresh events list
      await fetchMyEvents();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.deleteEvent(id);
    _isLoading = false;

    if (result['success']) {
      // Remove from local list
      _events.removeWhere((event) => event.id == id);
      notifyListeners();
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
