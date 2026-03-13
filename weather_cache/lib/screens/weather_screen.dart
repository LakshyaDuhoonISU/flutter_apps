import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController = TextEditingController();
  final WeatherService _weatherService = WeatherService();

  // State variables
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;

  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  // Handle search button press
  Future<void> _searchWeather() async {
    final city = _cityController.text.trim();

    // ERROR HANDLING: Empty input validation
    if (city.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a city name';
        _weatherData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch weather data (will check cache automatically)
      final data = await _weatherService.getWeather(city);

      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _weatherData = null;

        // ERROR HANDLING: Display appropriate error messages
        if (e.toString().contains('City not found')) {
          _errorMessage = 'City not found';
        } else {
          _errorMessage =
              'Unable to fetch weather. Check your internet connection.';
        }
      });
    }
  }

  // Handle refresh button press
  // Forces API call and updates cache
  Future<void> _refreshWeather() async {
    final city = _cityController.text.trim();

    // ERROR HANDLING: Empty input validation
    if (city.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a city name';
        _weatherData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Force refresh from API
      final data = await _weatherService.getWeather(city, forceRefresh: true);

      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;

        // ERROR HANDLING: Display appropriate error messages
        if (e.toString().contains('City not found')) {
          _errorMessage = 'City not found';
        } else {
          _errorMessage =
              'Unable to fetch weather. Check your internet connection.';
        }
      });
    }
  }

  // Get display message based on data source
  String _getSourceMessage() {
    if (_weatherData == null) return '';

    final source = _weatherData!['source'];

    if (source == 'CACHE') {
      return 'Showing cached data';
    } else if (source == 'API') {
      return 'Showing fresh data from API';
    } else if (source == 'ERROR_CACHE') {
      return 'Network error. Showing cached data.';
    }

    return '';
  }

  // Get data source label for display
  String _getSourceLabel() {
    if (_weatherData == null) return '';

    final source = _weatherData!['source'];

    if (source == 'CACHE' || source == 'ERROR_CACHE') {
      return 'From Cache';
    } else if (source == 'API') {
      return 'From API';
    }

    return '';
  }

  // Format cached time
  String _formatCachedTime(DateTime time) {
    final formatter = DateFormat('MMM dd, yyyy • hh:mm:ss a');
    return formatter.format(time);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Cache App'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Enter city name',
                hintText: 'e.g., London',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_city),
              ),
              onSubmitted: (_) => _searchWeather(),
            ),
            const SizedBox(height: 12),

            // Action buttons row
            Row(
              children: [
                // Search button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _searchWeather,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Refresh button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _refreshWeather,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Loading indicator
            if (_isLoading) const Center(child: CircularProgressIndicator()),

            // Error message display
            if (_errorMessage != null && !_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Weather data display card
            if (_weatherData != null && !_isLoading)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Data source message
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _weatherData!['source'] == 'API'
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _weatherData!['source'] == 'API'
                                  ? Icons.cloud_download
                                  : Icons.storage,
                              color: _weatherData!['source'] == 'API'
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getSourceMessage(),
                              style: TextStyle(
                                color: _weatherData!['source'] == 'API'
                                    ? Colors.green.shade700
                                    : Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Weather information card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // City name
                              Text(
                                (_weatherData!['weather'] as Weather).cityName,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Weather condition
                              Text(
                                (_weatherData!['weather'] as Weather).condition,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Temperature
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.thermostat,
                                    size: 40,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(_weatherData!['weather'] as Weather).temperature.toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Humidity
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.water_drop,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Humidity: ${(_weatherData!['weather'] as Weather).humidity}%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              const Divider(),
                              const SizedBox(height: 12),

                              // Data source label
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Data Source:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _weatherData!['source'] == 'API'
                                          ? Colors.green
                                          : Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getSourceLabel(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Last cached time
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Last Cached:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _formatCachedTime(
                                      _weatherData!['cachedTime'] as DateTime,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
