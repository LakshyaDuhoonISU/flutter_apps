// Test List Screen
// Displays all tests for a specific course

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/test_service.dart';
import '../models/test_model.dart';
import '../utils/constants.dart';
import 'test_screen.dart';
import 'subscription_screen.dart';

class TestListScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const TestListScreen({
    Key? key,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  late Future<List<TestModel>> _testsFuture;
  String _subscriptionType = 'none';

  @override
  void initState() {
    super.initState();
    _testsFuture = TestService.getTestsByCourse(widget.courseId);
    _loadSubscriptionType();
  }

  // Load subscription type from SharedPreferences
  Future<void> _loadSubscriptionType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _subscriptionType = prefs.getString(subscriptionTypeKey) ?? 'none';
    });
  }

  // Refresh tests
  Future<void> _refreshTests() async {
    setState(() {
      _testsFuture = TestService.getTestsByCourse(widget.courseId);
    });
    await _loadSubscriptionType();
  }

  // Check if user has access to test
  bool _hasAccessToTest(TestModel test) {
    // Free tests are always accessible
    if (test.isFree) return true;

    // Plus subscription has access to everything
    if (_subscriptionType == 'plus') return true;

    // Test series subscription has access to all tests
    if (_subscriptionType == 'test-series') return true;

    // Individual course subscription has access (assuming they enrolled)
    if (_subscriptionType == 'individual') return true;

    // No valid subscription
    return false;
  }

  // Show subscription required dialog
  Future<void> _showSubscriptionDialog() async {
    final goToSubscription = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Required'),
        content: const Text(
          'This test requires a valid subscription plan. Would you like to view our subscription plans?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );

    if (goToSubscription == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
      );
      // Reload subscription type after returning
      await _loadSubscriptionType();
    }
  }

  // Handle test tap
  void _handleTestTap(TestModel test) {
    if (_hasAccessToTest(test)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => TestScreen(testId: test.id)),
      );
    } else {
      _showSubscriptionDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tests - ${widget.courseTitle}'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTests,
        child: FutureBuilder<List<TestModel>>(
          future: _testsFuture,
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshTests,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Success state
            final tests = snapshot.data!;

            // No tests found
            if (tests.isEmpty) {
              return const Center(
                child: Text(
                  'No tests available for this course',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            // Display tests
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: tests.length,
              itemBuilder: (context, index) {
                final test = tests[index];
                return _buildTestCard(test);
              },
            );
          },
        ),
      ),
    );
  }

  // Build test card widget
  Widget _buildTestCard(TestModel test) {
    final hasAccess = _hasAccessToTest(test);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _handleTestTap(test),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      test.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (test.isFree)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!hasAccess && !test.isFree)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Test description
              if (test.description.isNotEmpty)
                Text(
                  test.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Test info
              Row(
                children: [
                  _buildInfoChip(Icons.timer, '${test.durationMinutes} mins'),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.question_answer,
                    '${test.totalQuestions} questions',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.score, '${test.totalMarks} marks'),
                ],
              ),

              const SizedBox(height: 12),

              // Start test button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _handleTestTap(test),
                  icon: Icon(
                    hasAccess ? Icons.play_arrow : Icons.lock,
                    size: 20,
                  ),
                  label: Text(hasAccess ? 'Start Test' : 'Subscribe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasAccess ? null : Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for info chips
  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
