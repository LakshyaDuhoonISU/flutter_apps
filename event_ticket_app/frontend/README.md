# Event Ticket Booking - Flutter Frontend

A complete Flutter mobile application for event management and ticket booking with role-based authentication, Cloudinary image uploads, and comprehensive analytics.

## Features

### Authentication

- ✅ Login & Registration screens with validation
- ✅ JWT token storage using shared_preferences
- ✅ Role-based navigation (User, Organizer, Admin)
- ✅ Auto-login on app restart
- ✅ Persistent authentication state
- ✅ Secure logout

### User Features

- ✅ Browse all events with images
- ✅ View event details (date, time, location, price)
- ✅ Book tickets with quantity selection
- ✅ View personal bookings history
- ✅ Real-time ticket availability updates
- ✅ Auto-refresh after booking
- ✅ Indian Rupee (₹) currency display

### Organizer Features

- ✅ Create new events with image upload
- ✅ **Edit existing events** (title, description, location, date/time, price, image)
- ✅ View only their own events
- ✅ See event statistics (price, tickets sold, available tickets)
- ✅ View bookings for their events with attendee details
- ✅ Delete events with confirmation
- ✅ Pull-to-refresh event list
- ✅ **Cloudinary integration** for image uploads

### Admin Features

- ✅ Analytics dashboard with interactive charts
- ✅ View all events and bookings
- ✅ Revenue statistics and metrics
- ✅ Bar charts for visual analytics (fl_chart)
- ✅ Overview metrics (total events, bookings, revenue)
- ✅ Top users by bookings
- ✅ Event performance statistics

## Tech Stack

- **Framework**: Flutter (SDK ^3.10.8)
- **State Management**: Provider (^6.1.1)
- **HTTP Client**: http (^1.2.0)
- **Local Storage**: shared_preferences (^2.2.2)
- **Charts**: fl_chart (^0.66.0)
- **Date Formatting**: intl (^0.19.0)
- **Image Upload**: cloudinary_public (^0.21.0)
- **Image Picker**: image_picker (^1.0.7)

## Installation

### Prerequisites

- Flutter SDK 3.10.8 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Chrome (for web development)
- Backend server running on port 3000

### 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 2. Configure Backend URL

Open `lib/service/api_service.dart` and update the base URL:

```dart
// For Android Emulator:
static const String baseUrl = 'http://10.0.2.2:3000/api';

// For iOS Simulator:
static const String baseUrl = 'http://localhost:3000/api';

// For physical device (use your computer's IP):
static const String baseUrl = 'http://192.168.x.x:3000/api';

// For web:
static const String baseUrl = 'http://localhost:3000/api';
```

### 3. Configure Cloudinary (Required for Image Uploads)

Open `lib/utils/cloudinary_service.dart` and update with your Cloudinary credentials:

```dart
static const String cloudName = 'your_cloud_name';
static const String uploadPreset = 'your_upload_preset';
```

**To get Cloudinary credentials:**

1. Sign up at [cloudinary.com](https://cloudinary.com)
2. Get your cloud name from the dashboard
3. Create an unsigned upload preset in Settings → Upload
4. Name the preset 'event_images' or update the code accordingly

### 4. Run the App

```bash
# For web
flutter run -d chrome

# For Android
flutter run -d android

# For iOS
flutter run -d ios

# For all platforms
flutter run
```

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart                      # Entry point, MultiProvider setup
│   ├── models/
│   │   ├── User.dart                  # User model (id, name, email, role)
│   │   ├── Event.dart                 # Event model with toJson/fromJson
│   │   └── Booking.dart               # Booking model with user info
│   ├── providers/
│   │   ├── auth_provider.dart         # Authentication state management
│   │   ├── event_provider.dart        # Event state management (CRUD)
│   │   └── booking_provider.dart      # Booking state management
│   ├── screens/
│   │   ├── login_screen.dart          # Login UI
│   │   ├── register_screen.dart       # Registration UI
│   │   ├── event_list_screen.dart     # Browse events (User)
│   │   ├── event_detail_screen.dart   # Event details & booking
│   │   ├── my_bookings_screen.dart    # User's booking history
│   │   ├── organizer_dashboard_screen.dart     # Organizer home
│   │   ├── create_event_screen.dart   # Create event with image upload
│   │   ├── edit_event_screen.dart     # Edit event details
│   │   ├── organizer_event_bookings_screen.dart # Event bookings
│   │   └── admin_dashboard_screen.dart # Analytics & charts
│   ├── service/
│   │   └── api_service.dart           # HTTP API client (all endpoints)
│   └── utils/
│       └── cloudinary_service.dart    # Image upload service
├── android/                            # Android configuration
├── ios/                                # iOS configuration
├── web/                                # Web configuration
├── pubspec.yaml                        # Dependencies
└── README.md                           # This file
```

## Screens Overview

### Authentication Screens

**Login Screen** (`login_screen.dart`)

- Email and password fields with validation
- Role-based routing after login
- Error message display
- Navigate to registration

**Register Screen** (`register_screen.dart`)

- Name, email, password, and role selection
- Input validation
- Success/error feedback
- Auto-navigate to dashboard after registration

### User Screens

**Event List** (`event_list_screen.dart`)

- Grid view of all events with images
- Event title, date, location, price
- Tap to view details
- Auto-refresh after booking

**Event Detail** (`event_detail_screen.dart`)

- Full event information with large image
- Date, time, location, organizer info
- Available tickets counter
- Ticket quantity selector
- Total price calculation
- Book Now button
- Edit button (for organizers only)
- Hides booking section for event organizers

**My Bookings** (`my_bookings_screen.dart`)

- List of user's bookings
- Event title, date, tickets, total price
- Booking date and status

### Organizer Screens

**Organizer Dashboard** (`organizer_dashboard_screen.dart`)

- List of organizer's events only
- Event cards with image, title, stats
- Price, tickets sold, available tickets
- Three action buttons:
  - **Bookings**: View event bookings
  - **Edit**: Edit event details
  - **Delete**: Remove event
- Floating Action Button to create new event
- Pull-to-refresh

**Create Event** (`create_event_screen.dart`)

- Form fields: title, description, location, price, total tickets
- Date & time picker
- **Image picker** with preview
- **Cloudinary upload** with progress indicator
- Upload confirmation
- Form validation
- Creates event and returns to dashboard

**Edit Event** (`edit_event_screen.dart`)

- Pre-filled form with existing event data
- Update: title, description, location, date/time, price, tickets, image
- Shows current event image
- Option to upload new image
- Validates ticket count (cannot reduce below sold tickets)
- Auto-refreshes parent screen after update

**Event Bookings** (`organizer_event_bookings_screen.dart`)

- List of bookings for specific event
- Shows attendee name and email
- Number of tickets and total price
- Total tickets sold and revenue summary

### Admin Screens

**Admin Dashboard** (`admin_dashboard_screen.dart`)

- Overview metrics cards:
  - Total Events
  - Total Bookings
  - Total Revenue
- **Bar chart** showing revenue per event
- Event performance list with stats
- Top users by bookings
- Real-time data from backend aggregations

## State Management

The app uses **Provider** for state management with three main providers:

### AuthProvider (`auth_provider.dart`)

- Manages user authentication state
- Stores/retrieves JWT token
- Auto-login on app start
- Login/register/logout methods
- Current user information

```dart
// Usage
final authProvider = Provider.of<AuthProvider>(context);
if (authProvider.isLoggedIn) {
  // User is authenticated
}
```

### EventProvider (`event_provider.dart`)

- CRUD operations for events
- Fetches all events (public)
- Fetches organizer's events
- Create, update, delete events
- Error handling and loading states

```dart
// Usage
final eventProvider = Provider.of<EventProvider>(context);
await eventProvider.fetchAllEvents();
await eventProvider.createEvent(event);
await eventProvider.updateEvent(id, updates);
```

### BookingProvider (`booking_provider.dart`)

- Create bookings
- Fetch user's bookings
- Fetch event bookings (organizer)
- Booking validation
- Error handling

```dart
// Usage
final bookingProvider = Provider.of<BookingProvider>(context);
await bookingProvider.createBooking(eventId: id, numberOfTickets: 2);
```

## API Integration

The `ApiService` class handles all HTTP requests to the backend:

### Authentication

- `register()` - Create new user account
- `login()` - Authenticate user and get JWT token
- `logout()` - Clear stored credentials
- `getCurrentUser()` - Get user from local storage

### Events

- `getAllEvents()` - Get all events (public)
- `getMyEvents()` - Get organizer's events
- `getEventById(id)` - Get single event
- `createEvent(event)` - Create new event
- `updateEvent(id, updates)` - Update event (organizer)
- `deleteEvent(id)` - Delete event (organizer)

### Bookings

- `createBooking(eventId, numberOfTickets)` - Book tickets
- `getMyBookings()` - Get user's bookings
- `getEventBookings(eventId)` - Get bookings for event (organizer)

### Admin

- `getAllEventsAdmin()` - Get all events (admin)
- `getAllBookingsAdmin()` - Get all bookings (admin)
- `getAdminStats()` - Get analytics data

## Image Upload Flow

1. User taps "Pick & Upload Image" button
2. Image picker opens gallery
3. User selects image
4. Image is converted to bytes (Uint8List)
5. Preview is shown
6. Image uploads to Cloudinary in background
7. Success message and Cloudinary URL returned
8. URL is stored in event object
9. Image is displayed from Cloudinary CDN

## DateTime Handling

- Custom formatting to preserve local timezone
- No UTC conversion to avoid timezone bugs
- Format: `'yyyy-MM-ddTHH:mm:ss'` (without 'Z')
- Uses `.toLocal()` when parsing from backend
- Displays user-friendly formats with `intl` package

## Currency Display

- All prices displayed in Indian Rupee (₹)
- `Icons.currency_rupee` for rupee icon
- Two decimal places for prices: `price.toStringAsFixed(2)`

## User Flows

### User Journey

1. **Login** → Email + Password
2. **Event List** → Browse all events
3. **Event Detail** → Select event, choose ticket quantity
4. **Book Tickets** → Confirm booking
5. **My Bookings** → View purchase history
6. **Logout** → Clear session

### Organizer Journey

1. **Login** → Organizer credentials
2. **Dashboard** → View all created events
3. **Create Event** → Fill form, upload image
4. **Edit Event** → Update event details
5. **View Bookings** → See who booked tickets
6. **Manage Events** → Edit or delete events

### Admin Journey

1. **Login** → Admin credentials
2. **Analytics Dashboard** → View metrics
3. **Charts** → Revenue per event visualization
4. **Statistics** → Total events, bookings, revenue
5. **Manage** → Monitor all events and bookings

## Key Features Implementation

### Auto-Refresh Pattern

Events automatically refresh using Navigator result pattern:

```dart
// In event detail screen
Navigator.pop(context, true); // Return true when booking successful

// In event list screen
final result = await Navigator.push(...);
if (result == true) {
  eventProvider.fetchAllEvents(); // Auto-refresh
}
```

### Role-Based Navigation

```dart
// main.dart
if (role == 'user') return EventListScreen();
if (role == 'organizer') return OrganizerDashboardScreen();
if (role == 'admin') return AdminDashboardScreen();
```

### Ticket Validation

- Checks available tickets before booking
- Prevents overbooking
- Real-time availability updates
- Cannot reduce total tickets below sold amount

### Responsive Error Handling

- Network error messages
- Validation errors
- Success confirmations with SnackBars
- Loading indicators during async operations

## Development Notes

- All API calls use JWT authentication (stored in SharedPreferences)
- Images are optimized before upload (max 1920x1080, 85% quality)
- Pull-to-refresh on list screens
- Confirmation dialogs for destructive actions
- Material Design 3 components
- Supports Android, iOS, and Web platforms

## Testing

### Test Users

Create test accounts with different roles:

```dart
// User
email: user@test.com, password: pass123, role: user

// Organizer
email: org@test.com, password: pass123, role: organizer

// Admin
email: admin@test.com, password: pass123, role: admin
```

### Test Flow

1. **Register** three accounts (user, organizer, admin)
2. **Login as organizer** → Create events with images
3. **Login as user** → Book tickets
4. **Login as admin** → View analytics
5. **Test edit** → Update event details
6. **Test refresh** → Book tickets and verify auto-update

## Troubleshooting

### Backend Connection Issues

- Verify backend server is running on port 3000
- Check `baseUrl` in `api_service.dart` matches your setup
- For Android emulator, use `10.0.2.2` instead of `localhost`
- For physical devices, use computer's local IP address

### Image Upload Failures

- Verify Cloudinary credentials in `cloudinary_service.dart`
- Check upload preset is set to "unsigned"
- Ensure internet connection is active
- Check cloudinary.com dashboard for quota limits

### Authentication Issues

- Clear app data if tokens are corrupted
- Check JWT token expiration (7 days)
- Verify backend auth routes are working
- Check SharedPreferences for stored token

## Future Enhancements

- [ ] Payment gateway integration
- [ ] Push notifications for booking confirmations
- [ ] QR code ticket generation
- [ ] Event search and filtering
- [ ] Event categories/tags
- [ ] Social sharing
- [ ] Ticket cancellation and refunds
- [ ] Offline mode with local caching
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Email/SMS notifications
- [ ] Event reminders
- [ ] Rating and reviews system

## License

ISC

---

**Built with ❤️ using Flutter & Cloudinary**
