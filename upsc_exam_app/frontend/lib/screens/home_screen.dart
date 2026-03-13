// Home Screen
// Main dashboard after login showing navigation options

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'course_list_screen.dart';
import 'enrolled_courses_screen.dart';
import 'class_schedule_screen.dart';
import 'bookmarked_classes_screen.dart';
import 'current_affairs_screen.dart';
import 'community_screen.dart';
import 'subscription_screen.dart';
import 'profile_screen.dart';
import 'topper_talks_screen.dart';
import 'educator_courses_screen.dart';
import 'educator_pyq_screen.dart';
import 'educator_test_screen.dart';
import 'student_pyq_screen.dart';
import 'student_test_screen.dart';
import 'test_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userRole = '';
  String _subscriptionType = 'none';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString(userNameKey) ?? 'User';
      _userRole = prefs.getString(userRoleKey) ?? 'student';
      _subscriptionType = prefs.getString(subscriptionTypeKey) ?? 'none';
    });
  }

  // Handle logout
  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPSC Exam Prep'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $_userName!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Role: ${_userRole.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_subscriptionType == 'plus') ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'PLUS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Main navigation options
              const Text(
                'Quick Access',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // Courses button (only for students without test-series subscription)
              if (_userRole == 'student' && _subscriptionType != 'test-series')
                _buildMenuButton(
                  icon: Icons.book,
                  title: 'Courses',
                  subtitle: 'Browse and enroll in courses',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CourseListScreen(),
                      ),
                    );
                  },
                ),

              // Enrolled Courses button (only for students without test-series subscription)
              if (_userRole == 'student' &&
                  _subscriptionType != 'test-series') ...[
                const SizedBox(height: 15),
                _buildMenuButton(
                  icon: Icons.library_books,
                  title: 'Enrolled Courses',
                  subtitle: 'View your enrolled course content',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EnrolledCoursesScreen(),
                      ),
                    );
                  },
                ),
              ],

              // Class Schedule button (only for students without test-series subscription)
              if (_userRole == 'student' &&
                  _subscriptionType != 'test-series') ...[
                const SizedBox(height: 15),
                _buildMenuButton(
                  icon: Icons.calendar_today,
                  title: 'Class Schedule',
                  subtitle: 'View schedule of your classes',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ClassScheduleScreen(),
                      ),
                    );
                  },
                ),
              ],

              // My Notes button (only for students without test-series subscription)
              if (_userRole == 'student' &&
                  _subscriptionType != 'test-series') ...[
                const SizedBox(height: 15),
                _buildMenuButton(
                  icon: Icons.bookmark,
                  title: 'My Notes',
                  subtitle: 'View your bookmarked videos',
                  color: Colors.amber,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BookmarkedClassesScreen(),
                      ),
                    );
                  },
                ),
              ],

              // Practice PYQ button (only for students with plus or test-series subscription)
              if (_userRole == 'student' &&
                  (_subscriptionType == 'plus' ||
                      _subscriptionType == 'test-series')) ...[
                const SizedBox(height: 15),
                _buildMenuButton(
                  icon: Icons.question_answer,
                  title: 'Previous Year Questions',
                  subtitle: 'Practice previous year questions',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StudentPyqScreen(),
                      ),
                    );
                  },
                ),
              ],

              // Test Series button (only for students with plus or test-series subscription)
              if (_userRole == 'student' &&
                  (_subscriptionType == 'plus' ||
                      _subscriptionType == 'test-series')) ...[
                const SizedBox(height: 15),
                _buildMenuButton(
                  icon: Icons.quiz,
                  title: 'Test Series',
                  subtitle: 'Take tests and track your progress',
                  color: Colors.pink,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StudentTestScreen(),
                      ),
                    );
                  },
                ),
              ],

              // Test History button (only for students with plus or test-series subscription)
              if (_userRole == 'student' &&
                  (_subscriptionType == 'plus' ||
                      _subscriptionType == 'test-series')) ...[
                const SizedBox(height: 15),
                _buildMenuButton(
                  icon: Icons.history,
                  title: 'Test History',
                  subtitle: 'View your test attempts and results',
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TestHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],

              // My Courses button (only for educators)
              if (_userRole == 'educator') ...[
                const SizedBox(height: 15),
                _buildMenuButton(
                  icon: Icons.school,
                  title: 'My Courses',
                  subtitle: 'Manage your created courses',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EducatorCoursesScreen(),
                      ),
                    );
                  },
                ),
              ],

              // Manage PYQ button (only for educators)
              if (_userRole == 'educator') ...[
                const SizedBox(height: 15),
                _buildMenuButton(
                  icon: Icons.question_answer,
                  title: 'Previous Year Questions',
                  subtitle: 'Create and manage PYQs',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EducatorPyqScreen(),
                      ),
                    );
                  },
                ),
              ],

              // Manage Tests button (only for educators)
              if (_userRole == 'educator') ...[
                const SizedBox(height: 15),
                _buildMenuButton(
                  icon: Icons.quiz,
                  title: 'Test Series',
                  subtitle: 'Create and manage test series',
                  color: Colors.pink,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EducatorTestScreen(),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 15),

              // Current Affairs button
              _buildMenuButton(
                icon: Icons.newspaper,
                title: 'Current Affairs',
                subtitle: "Today's updates and quiz",
                color: Colors.orange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CurrentAffairsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              // Community button (hidden for test-series only students)
              if (_userRole != 'student' || _subscriptionType != 'test-series')
                _buildMenuButton(
                  icon: Icons.forum,
                  title: 'Community',
                  subtitle: 'Discussion forum',
                  color: Colors.green,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CommunityScreen(),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 15),

              // Topper Talks button
              _buildMenuButton(
                icon: Icons.video_library,
                title: 'Topper Talks',
                subtitle: 'Learn from UPSC toppers',
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TopperTalksScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              // Profile button (only for educators)
              if (_userRole == 'educator')
                _buildMenuButton(
                  icon: Icons.person,
                  title: 'Profile',
                  subtitle: 'View and edit your profile',
                  color: Colors.teal,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                    if (!mounted) return;
                    // Reload user data after returning from profile screen
                    _loadUserData();
                  },
                ),

              // Subscription button (only for students)
              if (_userRole == 'student') ...[
                const SizedBox(height: 15),
                _buildMenuButton(
                  icon: Icons.workspace_premium,
                  title: 'Subscription Plans',
                  subtitle: 'Upgrade to unlock premium features',
                  color: Colors.purple,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                    if (!mounted) return;
                    // Reload user data after returning from subscription screen
                    _loadUserData();
                  },
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build menu buttons
  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
