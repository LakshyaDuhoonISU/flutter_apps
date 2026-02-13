import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/login_screen.dart';
import 'screens/event_list_screen.dart';
import 'screens/organizer_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    // MultiProvider wraps the app with all providers (each screen can access these[similar to React Context])
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ), // Provider is a global app state
        ChangeNotifierProvider(
          create: (_) => EventProvider(),
        ), // ChangeNotifierProvider allows Providers to be available in the MyApp widget that use ChangeNotifier to manage state and notify listeners when state changes
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'Event Ticket Booking',
        debugShowCheckedModeBanner: false, // Remove debug banner in top right corner
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          ), // Flutter auto-generates a color scheme based on this seed color(like light/dark variants, primary/secondary colors etc.)
          useMaterial3:
              true, // Material 3 design (newer design language from Google with updated components and styles like rounded designs, new color system etc.)
        ),
        home: AuthWrapper(),
      ),
    );
  }
}

// Auth Wrapper - decides which screen to show based on login status and role
class AuthWrapper extends StatefulWidget {
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  void initState() {
    super.initState();
    // Check if user is already logged in when app starts
    Future.microtask(() {
      // Use Future.microtask to ensure this runs after the first build(since context may not be fully available during build process)
      Provider.of<AuthProvider>(
        context,
        listen: false,
      ).checkLoginStatus(); // listen: false because we are calling a function, not want to rebuild when auth state changes
    });
  }

  Widget build(BuildContext context) {
    // Listen to AuthProvider changes and rebuild UI when auth state changes
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking login status
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If not logged in, show login screen
        if (!authProvider.isLoggedIn) {
          return const LoginScreen();
        }

        // If logged in, navigate based on role
        final user = authProvider.currentUser!;

        // Role-based navigation
        switch (user.role) {
          case 'user':
            return const EventListScreen(); // User sees event list
          case 'organizer':
            return const OrganizerDashboardScreen(); // Organizer sees their events
          case 'admin':
            return const AdminDashboardScreen(); // Admin sees analytics
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
