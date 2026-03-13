# UPSC Exam Prep — Flutter Frontend

A full-featured **Flutter web + mobile app** for UPSC exam preparation, connected to a Node.js + Express + MongoDB + Socket.IO backend.

---

## 📱 Project Overview

This app provides separate experiences for **students** and **educators**:

**Students** can:

- Browse and enroll in courses
- Watch live classes with real-time chat, polls, and doubts
- Watch recorded videos and track completion progress
- Bookmark classes and take personal notes
- View today's class schedule
- Take tests and view detailed results
- Practice Previous Year Questions (PYQ)
- Read daily current affairs and take quizzes
- Participate in the community forum
- Watch topper talk videos

**Educators** can:

- Create and manage courses, topics, and classes
- Conduct live classes with interactive tools (polls, doubt resolution, chat moderation)
- Create tests and add questions
- Add current affairs, topper talks, and PYQ sets
- Manage the community forum (pin posts)

---

## 🛠 Tech Stack

| Technology         | Purpose                          |
| ------------------ | -------------------------------- |
| Flutter            | Cross-platform UI framework      |
| Dart               | Programming language             |
| http               | REST API calls                   |
| shared_preferences | Local JWT/user data storage      |
| socket_io_client   | Real-time live class interaction |
| intl               | Date/time formatting             |
| url_launcher       | Open external links              |

### State Management

- `setState` for widget-level state
- `FutureBuilder` for async API data
- No external state management libraries (no Bloc / Provider / Riverpod)

---

## 📁 Folder Structure

```
lib/
│
├── main.dart                             # Entry point + auth check
│
├── models/
│   ├── user_model.dart
│   ├── course_model.dart
│   ├── test_model.dart
│   ├── question_model.dart
│   ├── test_result_model.dart
│   ├── live_class_models.dart            # LiveChat, LivePoll, LiveDoubt
│   └── pyq_set_model.dart
│
├── services/
│   ├── api_service.dart                  # Base HTTP + token management
│   ├── auth_service.dart                 # Login, register, logout
│   ├── course_service.dart               # Courses, schedule, bookmarks, notes
│   ├── test_service.dart                 # Tests, submit, results
│   ├── socket_service.dart               # Socket.IO singleton (live class)
│   └── pyq_service.dart                  # PYQ sets
│
├── screens/
│   │
│   ├── — Auth —
│   ├── login_screen.dart
│   ├── register_screen.dart
│   │
│   ├── — Student —
│   ├── home_screen.dart                  # Dashboard (role-aware)
│   ├── course_list_screen.dart           # Browse all courses
│   ├── course_detail_screen.dart         # Course info + enroll
│   ├── enrolled_courses_screen.dart      # My enrolled courses
│   ├── enrolled_course_detail_screen.dart # Watch videos + live interaction
│   ├── class_schedule_screen.dart        # Today's schedule (date-filterable)
│   ├── bookmarked_classes_screen.dart    # Bookmarked recorded classes
│   ├── student_test_screen.dart          # Take a test
│   ├── test_list_screen.dart             # Tests for a course
│   ├── test_history_screen.dart          # Past test attempts
│   ├── result_screen.dart                # Detailed test result analysis
│   ├── student_pyq_screen.dart           # Browse and answer PYQs
│   ├── current_affairs_screen.dart       # Today's current affairs + quiz
│   ├── community_screen.dart             # Forum post list
│   ├── post_detail_screen.dart           # Post + replies
│   ├── create_post_screen.dart           # New forum post
│   ├── topper_talks_screen.dart          # Video library of topper sessions
│   ├── subscription_screen.dart          # Subscription plans
│   ├── profile_screen.dart               # User profile
│   │
│   ├── — Educator —
│   ├── educator_courses_screen.dart      # My courses list
│   ├── manage_course_screen.dart         # Create / edit a course
│   ├── manage_topics_screen.dart         # Topics + classes management + live video
│   ├── manage_topic_form_screen.dart     # Create / edit a topic
│   ├── manage_class_form_screen.dart     # Create / edit a class/video
│   ├── educator_test_screen.dart         # Create / manage tests
│   ├── educator_pyq_screen.dart          # Create / manage PYQ sets
│   ├── create_current_affairs_screen.dart # Add current affairs
│   └── add_topper_talk_screen.dart       # Add topper talk video
│
├── widgets/
│   ├── live_class_interaction_widget.dart # Chat / Polls / Doubts tabs
│   ├── course_card.dart
│   ├── question_card.dart
│   └── answer_option.dart
│
└── utils/
    ├── constants.dart                    # baseUrl, socketBaseUrl, key names
    └── video_status_helper.dart          # upcoming / live / recorded logic
```

---

## 🔌 Backend Connection

Edit `lib/utils/constants.dart`:

```dart
const String baseUrl = 'http://localhost:3000/api';     // REST API
const String socketBaseUrl = 'http://localhost:3000';   // Socket.IO
```

For a physical device replace `localhost` with your machine's LAN IP.

---

## 📦 Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  http: ^1.2.0
  shared_preferences: ^2.2.2
  url_launcher: ^6.3.1
  socket_io_client: ^2.0.3+1
  intl: ^0.19.0
```

---

## 🔐 Auth & Storage

On login/register the token and user data are saved to SharedPreferences under these keys (defined in `constants.dart`):

| Key                 | Value                       |
| ------------------- | --------------------------- |
| `jwt_token`         | JWT string                  |
| `user_id`           | MongoDB `_id`               |
| `user_name`         | Display name                |
| `user_email`        | Email                       |
| `user_role`         | `'student'` or `'educator'` |
| `subscription_type` | Subscription tier           |

All HTTP requests from `ApiService` automatically include `Authorization: Bearer <token>`.

Logout calls `SocketService.disconnect()` (which clears the socket cache) before removing stored credentials.

---

## 🔌 Socket Service

`SocketService` is a static singleton in `socket_service.dart`. Key behaviours:

- `initialize(baseUrl)` — reads the current JWT from SharedPreferences, compares tokens, and creates a **new** socket with `forceNew: true` if the user has changed. Uses `IO.cache.clear()` to prevent the old Manager from ghost-reconnecting.
- `disconnect()` — calls `dispose()` (not `disconnect()`) on the socket and then `IO.cache.clear()`, ensuring no auto-reconnect fires after logout.
- All socket events are wrapped in typed methods: `joinClass`, `leaveClass`, `sendChat`, `deleteChat`, `createPoll`, `votePoll`, `raiseDoubt`, `answerDoubt`, `deleteDoubt`.

---

## 📺 Video Status Logic

`VideoStatusHelper.getVideoStatus(scheduledAt, durationMinutes)` returns:

| Status     | Condition                                     |
| ---------- | --------------------------------------------- |
| `upcoming` | `now < scheduledAt`                           |
| `live`     | `scheduledAt <= now < scheduledAt + duration` |
| `recorded` | `now >= scheduledAt + duration`               |

The educator `ManageTopicsScreen` runs a `Timer.periodic(30s)` to keep status badges accurate without navigating away, and calls `setState` after closing the video dialog for immediate feedback.

---

## 🎥 Live Class Interaction

`LiveClassInteractionWidget` is a tabbed panel (Chat · Polls · Doubts) rendered below the YouTube iframe player.

- **Chat tab** — all users can send messages; educators can delete any message.
- **Polls tab**
  - Educator: scrollable list of all polls (LIVE / ENDED badge), live vote counts, Create Poll button (disabled while a poll is running).
  - Student: active poll shows voting buttons; ended polls show results bars below.
  - All polls (active + ended) are loaded via `polls-history` on join — no data is lost after rejoin or login-switch.
- **Doubts tab** — students submit questions; educators see all doubts and can answer or delete; answers broadcast in real time.
- On `class-ended` event the widget calls `onClassEnded()` which pops the video dialog automatically for both educator and student.

---

## 📅 Class Schedule Screen

- Opens defaulted to **today's date**.
- Calendar icon → pick any other date.
- X button → show all days.
- "No classes today" shows a "Show all days" fallback button.

---

## 🚀 Running the App

```bash
cd frontend
flutter pub get  # install dependencies
flutter run -d chrome  # web (recommended for Socket.IO)
# or
flutter run  # Android / iOS
```

Make sure the backend is running first:

```bash
cd backend && npm run dev
```

---

## ✅ Implemented Features

### Auth

- Register / login with role selection
- JWT stored in SharedPreferences
- Auto-login on restart
- Safe logout (socket disconnect + credential clear)

### Student Features

- Browse and enroll in courses
- Watch live classes with Socket.IO interaction (chat, polls, doubts)
- Watch recorded videos; player auto-closes when live → recorded transition fires
- Mark classes as watched, track completion %
- Bookmark recorded classes
- Personal notes per class (CRUD)
- Today's class schedule (date-filterable)
- Take timed tests, view detailed per-question analysis
- Browse and answer Previous Year Questions
- Daily current affairs with quiz
- Community forum (create post, reply, upvote)
- Topper talk video library
- Subscription plans view
- Profile screen

### Educator Features

- Create and manage courses (CRUD)
- Manage topics and classes within a course
- Conduct live classes: status badge auto-refreshes (every 30 s), video dialog opens in live mode
- Live class tools: create polls, answer doubts, moderate chat
- Create and manage tests with questions
- Create PYQ sets
- Add current affairs content
- Add topper talk videos
- Pin / unpin community posts

A complete **Flutter mobile application** for UPSC (Union Public Service Commission) exam preparation. This app connects to a Node.js + Express + MongoDB backend to provide students with courses, tests, current affairs, and community discussions.

---

## 📱 Project Overview

This is the **frontend mobile application** for the UPSC Exam Preparation platform. It provides an intuitive and clean user interface for students and educators to access educational content, take tests, view current affairs, and participate in community discussions.

This is a **college project** designed with simplicity in mind - using basic Flutter concepts without complex state management libraries.

---

## 🛠 Tech Stack

- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **HTTP** - For REST API calls to backend
- **SharedPreferences** - For local storage of JWT tokens and user data
- **Material Design** - UI components

### No Complex State Management

- ✅ Uses `setState` for state management
- ✅ Uses `FutureBuilder` for async operations
- ❌ No Bloc, Provider, or Riverpod
- ❌ No GetX or other state management libraries

---

## 📁 Folder Structure

```
lib/
│
├── main.dart                      # App entry point with authentication check
│
├── models/                        # Data models
│   ├── user_model.dart           # User model (Student/Educator)
│   ├── course_model.dart         # Course model
│   ├── test_model.dart           # Test model
│   ├── question_model.dart       # Question model
│   └── test_result_model.dart    # Test result model
│
├── services/                      # API service layer
│   ├── api_service.dart          # Base HTTP service
│   ├── auth_service.dart         # Authentication API calls
│   ├── course_service.dart       # Course-related API calls
│   └── test_service.dart         # Test-related API calls
│
├── screens/                       # UI screens
│   ├── login_screen.dart         # User login
│   ├── register_screen.dart      # User registration
│   ├── home_screen.dart          # Main dashboard
│   ├── course_list_screen.dart   # List all courses
│   ├── course_detail_screen.dart # Course details
│   ├── test_list_screen.dart     # Tests for a course
│   ├── test_screen.dart          # Take test
│   ├── result_screen.dart        # View test results
│   ├── current_affairs_screen.dart  # Daily current affairs
│   └── community_screen.dart     # Community forum
│
├── widgets/                       # Reusable widgets
│   ├── course_card.dart          # Course display card
│   ├── question_card.dart        # Question display card
│   └── answer_option.dart        # Answer option widget
│
└── utils/
    └── constants.dart             # App constants (API URL, keys)
```

---

## 🎨 Features Implemented

### ✅ Authentication

- User registration (Student/Educator)
- User login with JWT tokens
- Token storage using SharedPreferences
- Auto-login on app restart
- Logout functionality

### ✅ Home Dashboard

- Welcome message with user name
- Quick access to all features
- Role display (Student/Educator)
- Clean navigation buttons

### ✅ Courses

- Browse all available courses
- View course details
- See educator information
- Enroll in courses
- View enrolled students count
- Price display with Plus badge

### ✅ Tests

- View tests for each course
- Take tests with timer
- One question at a time navigation
- Answer selection with radio buttons
- Submit test with confirmation
- Progress indicator

### ✅ Test Results

- Detailed score display
- Accuracy percentage
- Correct/Wrong/Unattempted counts
- Question-wise analysis
- Color-coded answers (green/red/orange)
- Answer explanations

### ✅ Current Affairs

- Daily current affairs content
- Quiz questions with explanations
- Category-based content

### ✅ Community Forum

- View all posts
- Pinned posts highlighting
- Upvote counts
- Reply counts
- Author information

---

## 📊 Screens Explanation

### 1. **Login Screen** (`login_screen.dart`)

- Email and password input fields
- Form validation
- Loading indicator during login
- Error messages via SnackBar
- Navigation to register screen

### 2. **Register Screen** (`register_screen.dart`)

- Name, email, password input
- Role selection (Student/Educator)
- Form validation
- Auto-login after registration

### 3. **Home Screen** (`home_screen.dart`)

- Welcome card with user info
- Navigation buttons to:
  - Courses
  - Current Affairs
  - Community
- Logout button in AppBar
- Role badge display

### 4. **Course List Screen** (`course_list_screen.dart`)

- Displays all courses in a list
- Shows course cards with:
  - Title and subject
  - Description preview
  - Educator name
  - Student count
  - Price
  - Plus badge (if applicable)
- Pull to refresh
- Tap to view course details

### 5. **Course Detail Screen** (`course_detail_screen.dart`)

- Full course information
- Enroll button
- View tests button
- Educator information
- Price and Plus status

### 6. **Test List Screen** (`test_list_screen.dart`)

- Lists all tests for a course
- Shows:
  - Test title and description
  - Duration
  - Total questions
  - Total marks
  - Free badge (if applicable)
- Start test button

### 7. **Test Screen** (`test_screen.dart`)

- One question at a time
- Progress indicator
- Question counter
- Answer selection (A, B, C, D)
- Previous/Next navigation
- Submit button on last question
- Back navigation prevention with confirmation

### 8. **Result Screen** (`result_screen.dart`)

- Score display card
- Statistics (Correct/Wrong/Unattempted)
- Question-wise analysis:
  - Question text
  - All options
  - Selected answer highlighted
  - Correct answer highlighted
  - Explanation (if available)
  - Difficulty badge
- Color coding:
  - Green for correct
  - Red for wrong
  - Orange for unattempted

### 9. **Current Affairs Screen** (`current_affairs_screen.dart`)

- Today's current affairs title
- Full summary
- Quiz questions with:
  - Multiple choice options
  - Explanations

### 10. **Community Screen** (`community_screen.dart`)

- List of community posts
- Pinned posts at top
- Post information:
  - Title and content preview
  - Author name
  - Upvote count
  - Reply count
- Floating action button for creating posts (placeholder)

---

## 🔌 Backend Connection

### API Base URL Configuration

Edit `lib/utils/constants.dart`:

```dart
// For Android Emulator
const String baseUrl = "http://10.0.2.2:5000/api";

// For iOS Simulator
const String baseUrl = "http://localhost:5000/api";

// For Physical Device (use your computer's IP)
const String baseUrl = "http://192.168.1.x:5000/api";
```

### How API Calls Work

1. **Authentication Flow:**

   ```
   User Login/Register → Backend sends JWT token →
   Token saved in SharedPreferences →
   All future API calls include token in Authorization header
   ```

2. **API Service (`api_service.dart`):**
   - Handles GET, POST, PUT, DELETE requests
   - Automatically includes JWT token from SharedPreferences
   - Centralized error handling

3. **Specific Services:**
   - `auth_service.dart` - Login, Register, GetUser
   - `course_service.dart` - Get courses, Enroll
   - `test_service.dart` - Get tests, Submit test

---

## 📡 API Endpoints Used

### Authentication

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user

### Courses

- `GET /api/courses` - Get all courses
- `GET /api/courses/:id` - Get single course
- `POST /api/courses/:id/enroll` - Enroll in course
- `GET /api/courses/my-courses` - Get enrolled courses

### Tests

- `GET /api/tests/:courseId` - Get tests for course
- `GET /api/tests/test/:id` - Get test with questions
- `POST /api/tests/test/submit` - Submit test answers
- `GET /api/tests/test/results/:testId` - Get test results

### Current Affairs

- `GET /api/current-affairs/today` - Get today's current affairs

### Community

- `GET /api/community` - Get all community posts
- `GET /api/community/:id` - Get single post
- `POST /api/community` - Create new post
- `POST /api/community/reply/:postId` - Add reply

---

## 🚀 How to Run the Project

### Prerequisites

- Flutter SDK (3.10.8 or higher)
- Dart SDK (included with Flutter)
- Android Studio / VS Code
- Android Emulator or iOS Simulator or Physical Device
- Backend server running (see backend README)

### Installation Steps

1. **Navigate to frontend folder:**

   ```bash
   cd frontend
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Configure API URL:**

   Edit `lib/utils/constants.dart` and set the correct base URL for your backend.

4. **Run the backend server:**

   Make sure the backend is running on `http://localhost:5000`

   ```bash
   cd ../backend
   npm run dev
   ```

5. **Run the Flutter app:**

   ```bash
   flutter run
   ```

   Or use your IDE's run button (VS Code or Android Studio).

6. **Select device:**
   - For Android Emulator: Start emulator first
   - For iOS Simulator: Requires macOS
   - For Physical Device: Enable USB debugging

---

## 📦 Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP requests to backend
  http: ^1.1.0

  # Local storage for JWT tokens
  shared_preferences: ^2.2.2

  # Material icons
  cupertino_icons: ^1.0.8
```

### How to Add Dependencies

```bash
flutter pub add http
flutter pub add shared_preferences
flutter pub get
```

---

## 🔐 Authentication & Security

### JWT Token Management

**How it works:**

1. User logs in with email/password
2. Backend validates credentials
3. Backend sends JWT token
4. App saves token in SharedPreferences
5. All future API calls include: `Authorization: Bearer <token>`

**Implementation:**

```dart
// Save token (in auth_service.dart)
await ApiService.saveToken(token);

// Get token (in api_service.dart)
final token = await getToken();

// Use token in headers
headers: {
  'Authorization': 'Bearer $token',
}
```

### User Data Storage

Stored in SharedPreferences:

- JWT token
- User ID
- User name
- User email
- User role

---

## 🎯 State Management Approach

This project uses **simple state management** suitable for beginners:

### setState()

Used for:

- Updating UI when data changes
- Form input handling
- Loading states
- Answer selection in tests

Example:

```dart
setState(() {
  _isLoading = true;
});
```

### FutureBuilder

Used for:

- Loading data from API
- Handling loading, error, and success states
- Automatic UI updates

Example:

```dart
FutureBuilder<List<Course>>(
  future: CourseService.getAllCourses(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    return ListView(...);
  },
)
```

**No complex patterns:**

- ❌ No Bloc
- ❌ No Provider
- ❌ No Riverpod
- ❌ No GetX

---

## 🎨 UI/UX Design Principles

### Material Design

- Uses Material 3 components
- Consistent color scheme
- Standard padding and spacing

### Loading States

- `CircularProgressIndicator` during API calls
- Skeleton screens for better UX

### Error Handling

- SnackBar for error messages
- Error icons and retry buttons
- User-friendly error messages

### Navigation

- Standard Flutter navigation (push/pop)
- No named routes (keeping it simple)
- Back button confirmation on test screen

### Color Coding

- 🟢 Green - Correct answers, success
- 🔴 Red - Wrong answers, errors
- 🟠 Orange - Unattempted, warnings
- 🔵 Blue - Primary actions, info
- 🟣 Purple - Plus subscription badge

---

## 🧪 Testing the App

### Manual Testing Steps

1. **Test Registration:**
   - Open app → Register screen
   - Fill details → Select role → Register
   - Should navigate to Home screen

2. **Test Login:**
   - Logout → Login screen
   - Enter credentials → Login
   - Should navigate to Home screen

3. **Test Courses:**
   - Home → Courses button
   - Should show list of courses
   - Tap a course → Should show details
   - Tap Enroll → Should show success message

4. **Test Taking:**
   - Course detail → View Tests
   - Select a test → Start Test
   - Answer questions → Previous/Next
   - Submit test → View results

5. **Test Current Affairs:**
   - Home → Current Affairs
   - Should show today's content and quiz

6. **Test Community:**
   - Home → Community
   - Should show posts with upvotes and replies

---

## 📱 Platform-Specific Notes

### Android

- Min SDK: 21 (Android 5.0)
- Target SDK: 34
- Permissions: Internet (already in manifest)

### iOS

- Min iOS version: 12.0
- Requires macOS for building
- Run: `flutter run -d ios`

### Web (Optional)

- Can run on web with: `flutter run -d chrome`
- But primarily designed for mobile

---

## 🐛 Common Issues & Solutions

### Issue 1: Cannot connect to backend

**Error:** `Failed to load data` or `Connection refused`

**Solution:**

- Make sure backend is running: `npm run dev`
- Check API URL in `constants.dart`
- For Android Emulator, use `10.0.2.2` not `localhost`
- For Physical Device, use computer's IP address

### Issue 2: Token invalid or expired

**Error:** `Not authorized` or `Token failed`

**Solution:**

- Logout and login again
- Token expires after 30 days (configurable in backend)
- Check if backend JWT_SECRET is consistent

### Issue 3: App showing blank screen

**Solution:**

- Check if backend is running
- Check console for errors
- Clear app data and restart

### Issue 4: Build errors after adding dependencies

**Solution:**

```bash
flutter clean
flutter pub get
flutter run
```

---

## 📚 Code Examples

### Making API Call with Error Handling

```dart
try {
  final courses = await CourseService.getAllCourses();
  // Success - use courses
} catch (e) {
  // Error - show message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

### Navigating Between Screens

```dart
// Push new screen
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => CourseDetailScreen(courseId: id),
  ),
);

// Replace screen (for login → home)
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => HomeScreen(),
  ),
);

// Go back
Navigator.of(context).pop();
```

### Using FutureBuilder

```dart
FutureBuilder<List<Course>>(
  future: _coursesFuture,
  builder: (context, snapshot) {
    // Loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    // Error
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    // Success
    final courses = snapshot.data!;
    return ListView.builder(...);
  },
)
```

---

## 🎓 Learning Outcomes

This project demonstrates:

- ✅ Flutter basics (Widgets, State, Navigation)
- ✅ REST API integration
- ✅ HTTP requests (GET, POST)
- ✅ Local storage with SharedPreferences
- ✅ Form validation
- ✅ List rendering with ListView
- ✅ Authentication flow
- ✅ Error handling
- ✅ Async/await patterns
- ✅ Material Design implementation
- ✅ Code organization and structure

---

## 📝 File Naming Conventions

- Screens: `*_screen.dart`
- Models: `*_model.dart`
- Services: `*_service.dart`
- Widgets: `*_widget.dart` or descriptive names
- Use snake_case for file names
- Use PascalCase for class names

---

## 🚧 Future Enhancements

Potential features to add:

- [ ] Search functionality for courses
- [ ] Filter courses by subject
- [ ] Profile screen with edit options
- [ ] Bookmark current affairs
- [ ] Save test results locally
- [ ] Notifications for new content
- [ ] Dark mode support
- [ ] Video player for course content
- [ ] Chat feature for live classes
- [ ] Payment integration for course purchase

---

## 🤝 Contributing

This is a college project. If you want to enhance it:

1. Fork the repository
2. Make your changes
3. Test thoroughly
4. Create a pull request with clear description

---

## 📄 License

This project is created for educational purposes as a college project.

---

## 👨‍💻 Project Structure Best Practices

### Models

- One model per file
- Include `fromJson` and `toJson` methods
- Clear property names
- Comments for complex fields

### Services

- Group related API calls
- Use try-catch for error handling
- Return typed objects, not raw JSON
- Clear function names

### Screens

- One screen per file
- Use StatefulWidget when state is needed
- Extract reusable widgets
- Keep build method clean

### Widgets

- Small, reusable components
- Accept parameters via constructor
- Use const constructors when possible
- Clear and descriptive names

---

## 📞 Support

For issues or questions:

- Check error messages in console
- Verify backend is running
- Check API URL configuration
- Review logs: `flutter logs`

---

## 🎯 Project Goals

This project aims to:

1. ✅ Provide a complete working Flutter app
2. ✅ Use simple, beginner-friendly code
3. ✅ Demonstrate REST API integration
4. ✅ Follow Flutter best practices
5. ✅ Maintain clean code structure
6. ✅ Include comprehensive comments
7. ✅ Work seamlessly with the backend

**Perfect for learning Flutter and building your portfolio!** 🚀

---

**Happy Coding! 📱✨**
