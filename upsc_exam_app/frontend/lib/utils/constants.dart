// Constants file
// Contains all constant values used throughout the app

// Backend API Base URL
// For Android Emulator: Use 10.0.2.2 instead of localhost
// For iOS Simulator: Use localhost
// For Physical Device: Use your computer's IP address (e.g., 192.168.1.x)
// For Chrome: Use http://localhost:3000 (with CORS enabled in backend)
const String baseUrl = "http://localhost:3000/api";

// Socket.IO Base URL (without /api path)
const String socketBaseUrl = "http://localhost:3000";

// SharedPreferences Keys
const String tokenKey = "jwt_token";
const String userIdKey = "user_id";
const String userNameKey = "user_name";
const String userEmailKey = "user_email";
const String userRoleKey = "user_role";
const String subscriptionTypeKey = "subscription_type";

// Colors
const int primaryColorValue = 0xFF6200EE;
const int accentColorValue = 0xFF03DAC6;
