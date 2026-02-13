# Event Ticket Booking System

A full-stack event management and ticket booking application with Flutter mobile frontend and Node.js/Express backend.

![Tech Stack](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white)
![Express.js](https://img.shields.io/badge/Express.js-404D59?style=for-the-badge)

## 📋 Overview

This system allows:

- **Users** to browse events and book tickets
- **Organizers** to create, edit, and manage events with image uploads
- **Admins** to view analytics and manage all events

### Key Features

✅ Role-based authentication (User, Organizer, Admin)  
✅ Event creation with Cloudinary image uploads  
✅ Real-time ticket availability tracking  
✅ Atomic booking to prevent overbooking  
✅ Event editing functionality for organizers  
✅ Analytics dashboard with charts  
✅ Auto-refresh after bookings  
✅ Indian Rupee (₹) currency support

## 🏗️ Architecture

**Backend:** Node.js + Express + MongoDB  
**Frontend:** Flutter (iOS, Android, Web)  
**Image Storage:** Cloudinary CDN  
**Authentication:** JWT tokens  
**State Management:** Provider pattern

---

## 🚀 Quick Start Guide

### Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v14 or higher) - [Download](https://nodejs.org/)
- **MongoDB** (v4.4 or higher) - [Download](https://www.mongodb.com/try/download/community)
- **Flutter SDK** (v3.10.8 or higher) - [Install Guide](https://docs.flutter.dev/get-started/install)
- **Git** - [Download](https://git-scm.com/)

Optional:

- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Chrome** (for web development)

---

## 📦 Installation & Setup

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd event_ticket_app
```

### Step 2: Backend Setup

#### 2.1 Navigate to Backend Directory

```bash
cd backend
```

#### 2.2 Install Dependencies

```bash
npm install
```

This installs:

- express (^4.18.2)
- mongoose (^8.9.4)
- bcryptjs (^2.4.3)
- jsonwebtoken (^9.0.2)
- cors (^2.8.5)

#### 2.3 Start MongoDB

**Option A: Using MongoDB Service**

```bash
# macOS
brew services start mongodb-community

# Linux
sudo systemctl start mongod

# Windows
net start MongoDB
```

**Option B: Manual Start**

```bash
mongod --dbpath /path/to/data/directory
```

**Verify MongoDB is Running:**

```bash
mongo --eval "db.runCommand({ ping: 1 })"
```

#### 2.4 Configure Environment (Optional)

The backend is configured to use:

- **Database:** `mongodb://localhost:27017/event-booking`
- **Port:** `3000`
- **JWT Secret:** `itm`

To customize, create a `.env` file:

```env
MONGO_URI=mongodb://localhost:27017/event-booking
PORT=3000
JWT_SECRET=itm
```

#### 2.5 Start Backend Server

```bash
npm start
```

**Expected Output:**

```
Server is running on port 3000
MongoDB connected successfully
```

**Verify Backend:**

```bash
curl http://localhost:3000/api/events
```

---

### Step 3: Frontend Setup

#### 3.1 Navigate to Frontend Directory

Open a **new terminal** window:

```bash
cd frontend
```

#### 3.2 Install Flutter Dependencies

```bash
flutter pub get
```

This installs all packages from `pubspec.yaml`:

- http (^1.2.0)
- provider (^6.1.1)
- shared_preferences (^2.2.2)
- fl_chart (^0.66.0)
- intl (^0.19.0)
- cloudinary_public (^0.21.0)
- image_picker (^1.0.7)

#### 3.3 Configure Backend URL

Open `frontend/lib/service/api_service.dart` and update the `baseUrl`:

**For Android Emulator:**

```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

**For iOS Simulator:**

```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**For Physical Device:**

```dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:3000/api';
```

**For Web:**

```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**To find your computer's IP:**

```bash
# macOS/Linux
ifconfig | grep "inet "

# Windows
ipconfig
```

#### 3.4 Configure Cloudinary (Required for Image Uploads)

1. Sign up at [cloudinary.com](https://cloudinary.com) (free tier available)
2. Get your **Cloud Name** from the dashboard
3. Create an **Upload Preset**:
   - Go to Settings → Upload
   - Click "Add upload preset"
   - Set signing mode to "Unsigned"
   - Name it `event_images`
   - Save

4. Open `frontend/lib/utils/cloudinary_service.dart`:

```dart
static const String cloudName = 'YOUR_CLOUD_NAME';      // Replace
static const String uploadPreset = 'event_images';      // Replace if different
```

#### 3.5 Run Flutter App

**Check Available Devices:**

```bash
flutter devices
```

**Run on Specific Platform:**

```bash
# Chrome (Web)
flutter run -d chrome

# Android Emulator
flutter run -d android

# iOS Simulator (macOS only)
flutter run -d ios

# Or let Flutter choose
flutter run
```

**Expected Output:**

```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Launching lib/main.dart on Chrome in debug mode...
```

---

## 🧪 Testing the Application

### Create Test Accounts

#### 1. Register a User

Open the app → Select **Register** → Fill in:

- Name: `Test User`
- Email: `user@test.com`
- Password: `pass123`
- Role: `User`

#### 2. Register an Organizer

- Name: `Test Organizer`
- Email: `organizer@test.com`
- Password: `pass123`
- Role: `Organizer`

#### 3. Register an Admin

- Name: `Test Admin`
- Email: `admin@test.com`
- Password: `pass123`
- Role: `Admin`

### Test Complete Flow

**As Organizer:**

1. Login with organizer account
2. Tap "Create Event" button
3. Fill event details and upload image
4. View created event in dashboard
5. Edit event details
6. View bookings (initially empty)

**As User:**

1. Login with user account
2. Browse events
3. Select an event
4. Choose number of tickets
5. Confirm booking
6. View "My Bookings"

**As Admin:**

1. Login with admin account
2. View analytics dashboard
3. See total events, bookings, revenue
4. Check bar charts

---

## 🔧 Troubleshooting

### Backend Issues

**Problem: MongoDB connection error**

```
Error: connect ECONNREFUSED 127.0.0.1:27017
```

**Solution:**

- Ensure MongoDB is running: `brew services list` (macOS) or `sudo systemctl status mongod` (Linux)
- Start MongoDB if stopped

**Problem: Port 3000 already in use**

```
Error: listen EADDRINUSE: address already in use :::3000
```

**Solution:**

```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or use different port in backend/server.js
```

### Frontend Issues

**Problem: Cannot connect to backend from Android emulator**

**Solution:** Use `10.0.2.2` instead of `localhost` in `api_service.dart`

**Problem: Cannot connect from physical device**

**Solution:**

1. Ensure device and computer are on same Wi-Fi
2. Use computer's local IP address
3. Disable firewall temporarily for testing

**Problem: Cloudinary upload fails**

**Solution:**

1. Verify credentials in `cloudinary_service.dart`
2. Check upload preset is set to "Unsigned"
3. Check internet connection
4. Verify Cloudinary account is active

**Problem: Image picker doesn't work**

**Solution:**

- **Android:** Add permissions to `android/app/src/main/AndroidManifest.xml`
- **iOS:** Add permissions to `ios/Runner/Info.plist`

### Common Flutter Issues

**Problem: `flutter pub get` fails**

**Solution:**

```bash
flutter clean
flutter pub get
```

**Problem: Build errors after pulling changes**

**Solution:**

```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

---

## 📱 Platform-Specific Setup

### Android

1. **Android Studio:** Install Android Studio with Android SDK
2. **Emulator:** Create AVD in AVD Manager
3. **Run:** `flutter run -d android`

### iOS (macOS only)

1. **Xcode:** Install from App Store
2. **CocoaPods:** Install with `sudo gem install cocoapods`
3. **Setup:**
   ```bash
   cd ios
   pod install
   cd ..
   flutter run -d ios
   ```

### Web

1. **Chrome:** Ensure Chrome is installed
2. **Enable Web:**
   ```bash
   flutter config --enable-web
   flutter run -d chrome
   ```

---

## 🗂️ Project Structure

```
event_ticket_app/
├── backend/                    # Node.js/Express API
│   ├── middleware/
│   │   └── auth.js            # JWT authentication & authorization
│   ├── models/
│   │   ├── User.js            # User schema
│   │   ├── Event.js           # Event schema
│   │   └── Booking.js         # Booking schema
│   ├── routes/
│   │   ├── authRoutes.js      # Login/Register
│   │   ├── eventRoutes.js     # Event CRUD
│   │   ├── bookingRoutes.js   # Booking operations
│   │   └── adminRoutes.js     # Admin analytics
│   ├── db.js                  # MongoDB connection
│   ├── server.js              # Express server setup
│   └── package.json
│
├── frontend/                   # Flutter mobile app
│   ├── lib/
│   │   ├── models/            # Data models
│   │   ├── providers/         # State management
│   │   ├── screens/           # UI screens
│   │   ├── service/           # API service
│   │   ├── utils/             # Cloudinary service
│   │   └── main.dart          # App entry point
│   ├── android/               # Android config
│   ├── ios/                   # iOS config
│   ├── web/                   # Web config
│   └── pubspec.yaml           # Flutter dependencies
│
├── README.md                   # This file
├── IMPLEMENTATION.md           # API & Screen documentation
```

---

## 📚 Documentation

- **[IMPLEMENTATION.md](./IMPLEMENTATION.md)** - Detailed API endpoints and screen documentation
- **[Backend README](./backend/README.md)** - Backend-specific documentation
- **[Frontend README](./frontend/README.md)** - Frontend-specific documentation

---

## 🔒 Security Notes

- JWT tokens expire after 7 days
- Passwords are hashed with bcrypt (10 salt rounds)
- Role-based access control prevents unauthorized actions
- Atomic operations prevent race conditions in booking
- CORS enabled for development (restrict in production)

**For Production:**

1. Use environment variables for sensitive data
2. Enable HTTPS
3. Restrict CORS to specific origins
4. Use stronger JWT secret
5. Implement rate limiting
6. Add input sanitization
7. Enable MongoDB authentication

---

## 🎯 Default Credentials

After setup, you can create these test accounts:

| Role      | Email              | Password | Purpose              |
| --------- | ------------------ | -------- | -------------------- |
| User      | user@test.com      | pass123  | Book tickets         |
| Organizer | organizer@test.com | pass123  | Create/manage events |
| Admin     | admin@test.com     | pass123  | View analytics       |

---

## 🛠️ Development Commands

### Backend

```bash
npm start              # Start server
npm install <package>  # Add new dependency
```

### Frontend

```bash
flutter run            # Run app
flutter pub get        # Install dependencies
flutter clean          # Clean build files
flutter build apk      # Build Android APK
flutter build ios      # Build iOS app
flutter build web      # Build web app
```

---

## 🚢 Deployment

### Backend Deployment

**Option 1: Heroku**

```bash
heroku create your-app-name
git push heroku main
heroku addons:create mongolab
```

**Option 2: Railway**

1. Connect GitHub repository
2. Add MongoDB plugin
3. Deploy automatically

**Option 3: AWS/DigitalOcean**

- Use PM2 for process management
- Setup Nginx reverse proxy
- Use MongoDB Atlas for database

### Frontend Deployment

**Android:**

```bash
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

**iOS:**

```bash
flutter build ios --release
# Open in Xcode and archive
```

**Web:**

```bash
flutter build web --release
# Deploy build/web folder to hosting
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the ISC License.

---

## 👨‍💻 Support

For issues and questions:

- Check [TROUBLESHOOTING](#-troubleshooting) section
- Review [IMPLEMENTATION.md](./IMPLEMENTATION.md)
- Open an issue on GitHub

---

## 🎓 Learning Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)
- [MongoDB Manual](https://docs.mongodb.com/manual/)
- [Provider State Management](https://pub.dev/packages/provider)

---

**Built with ❤️ using Flutter, Node.js, and MongoDB**

_Last Updated: February 2026_
