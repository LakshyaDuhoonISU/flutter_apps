import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String apiKey = "e8988573483b036cc946ddde037c0de6";
  static const String baseUrl =
      "https://api.openweathermap.org/data/2.5/weather";

  // Cache duration: EXACTLY 1 minute
  static const Duration cacheDuration = Duration(minutes: 1);

  // Main method to get weather data
  // Returns a Map with weather object, source (API/CACHE), and cached time
  Future<Map<String, dynamic>> getWeather(
    String city, {
    bool forceRefresh = false,
  }) async {
    try {
      // If not forcing refresh, check cache first
      if (!forceRefresh) {
        final cachedData = await _getCachedWeather(city);
        if (cachedData != null) {
          return cachedData;
        }
      }

      // Fetch fresh data from API
      final freshData = await _fetchWeatherFromAPI(city);
      return freshData;
    } catch (e) {
      // ERROR HANDLING: If API call fails, try to return cached data
      final cachedData = await _getCachedWeather(city, ignoreExpiry: true);
      if (cachedData != null) {
        // Return cached data with modified source message
        return {
          'weather': cachedData['weather'],
          'source': 'ERROR_CACHE',
          'cachedTime': cachedData['cachedTime'],
        };
      }
      // If no cached data exists, rethrow the error
      rethrow;
    }
  }

  // CACHE LOGIC: Check if valid cached data exists
  // Returns cached data if it exists and is less than 1 minute old
  Future<Map<String, dynamic>?> _getCachedWeather(
    String city, {
    bool ignoreExpiry = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Generate cache keys for this specific city
    final weatherKey = 'weather_$city';
    final timeKey = 'time_$city';

    // Check if cached data exists
    final weatherJson = prefs.getString(weatherKey);
    final timeString = prefs.getString(timeKey);

    if (weatherJson != null && timeString != null) {
      final savedTime = DateTime.parse(timeString);
      final currentTime = DateTime.now();

      // EXPIRY LOGIC: Check if cached data is less than 1 minute old
      final timeDifference = currentTime.difference(savedTime);
      final isExpired = timeDifference >= cacheDuration;

      // If not expired OR we're ignoring expiry (error case), return cached data
      if (!isExpired || ignoreExpiry) {
        final weatherData = json.decode(weatherJson);
        final weather = Weather.fromJson(weatherData);

        return {'weather': weather, 'source': 'CACHE', 'cachedTime': savedTime};
      }
    }

    // No valid cached data found
    return null;
  }

  // Fetch fresh weather data from OpenWeather API
  Future<Map<String, dynamic>> _fetchWeatherFromAPI(String city) async {
    final url = '$baseUrl?q=$city&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));

    // ERROR HANDLING: City not found
    if (response.statusCode == 404) {
      throw Exception('City not found');
    }

    // ERROR HANDLING: Other HTTP errors
    if (response.statusCode != 200) {
      throw Exception(
        'Unable to fetch weather. Check your internet connection.',
      );
    }

    final weatherData = json.decode(response.body);
    final weather = Weather.fromJson(weatherData);

    // Save to cache with current timestamp
    await _saveToCache(city, weatherData);

    final currentTime = DateTime.now();

    return {'weather': weather, 'source': 'API', 'cachedTime': currentTime};
  }

  // Save weather data and timestamp to SharedPreferences
  // Each city has its own cache keys: weather_$city and time_$city
  Future<void> _saveToCache(
    String city,
    Map<String, dynamic> weatherData,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Generate cache keys for this specific city
    final weatherKey = 'weather_$city';
    final timeKey = 'time_$city';

    // Save weather JSON
    await prefs.setString(weatherKey, json.encode(weatherData));

    // Save current timestamp
    await prefs.setString(timeKey, DateTime.now().toIso8601String());
  }
}
