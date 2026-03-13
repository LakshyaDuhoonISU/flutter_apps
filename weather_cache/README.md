# Weather Cache App

A Flutter mobile application that fetches weather data from OpenWeather API and implements smart caching using SharedPreferences.

## Features

- 🔍 Search weather by city name
- 💾 Cache weather data for 1 minute per city
- 🔄 Manual refresh to force fresh API data
- ⚡ Fast loading with cache
- 🎯 Clear indicators showing data source (Cache vs API)
- 🛡️ Comprehensive error handling

## How It Works

### Cache Logic

- Each city has its own cache keys: `weather_{city}` and `time_{city}`
- Cache duration is **exactly 1 minute**
- When you search:
  - ✅ If cached data exists AND is < 1 minute old → Shows cached data
  - ✅ If cached data is expired OR doesn't exist → Fetches from API
  - ✅ Network error with valid cache → Shows cached data with warning

### Data Displayed

- City name
- Temperature (Celsius)
- Weather condition
- Humidity
- Last cached time
- Data source label (From Cache / From API)

## Setup Instructions

### 1. Get OpenWeather API Key

1. Visit [OpenWeather API](https://openweathermap.org/api)
2. Sign up for a free account
3. Get your API key

### 2. Add API Key

Open `lib/services/weather_service.dart` and replace:

```dart
static const String apiKey = "YOUR_API_KEY";
```

with your actual API key:

```dart
static const String apiKey = "your_actual_api_key_here";
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
  ├── main.dart                    # App entry point
  ├── models/
  │   └── weather_model.dart       # Weather data model
  ├── services/
  │   └── weather_service.dart     # API & caching logic
  └── screens/
      └── weather_screen.dart      # Main UI screen
```

## Usage

1. **Search for a city**: Type city name and press "Search"
2. **View weather**: See temperature, humidity, and conditions
3. **Check data source**: Green badge = Fresh API data, Blue badge = Cached data
4. **Refresh**: Press "Refresh" button to force fetch from API

## Error Handling

- ❌ "City not found" → Invalid city name
- ❌ "Unable to fetch weather" → Network error with no cache
- ⚠️ "Network error. Showing cached data" → Network error but cache available
- ⚠️ "Please enter a city name" → Empty search input

## Cache Behavior Examples

**Scenario 1:**

- Search "London" → Fetches from API ✅
- Wait 30 seconds → Search "London" again → Shows cache ⚡
- Wait 60+ seconds → Search "London" again → Fetches from API ✅

**Scenario 2:**

- Search "Paris" → Fetches from API ✅
- Search "Tokyo" → Fetches from API ✅
- Each city has independent cache ✅

## Technologies Used

- Flutter SDK
- `http` package for API calls
- `shared_preferences` for local caching
- `intl` package for date formatting

## License

This project is created for educational purposes.

---

**Note:** Make sure to add your OpenWeather API key before running the app!
