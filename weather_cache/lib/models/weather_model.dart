// Weather model to represent weather data
class Weather {
  final String cityName;
  final double temperature;
  final int humidity;
  final String condition;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.humidity,
    required this.condition,
  });

  // Factory constructor to create Weather object from JSON
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: (json['main']['temp'] as num).toDouble(),
      humidity: json['main']['humidity'],
      condition: json['weather'][0]['main'],
    );
  }

  // Convert Weather object to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'name': cityName,
      'main': {'temp': temperature, 'humidity': humidity},
      'weather': [
        {'main': condition},
      ],
    };
  }
}
