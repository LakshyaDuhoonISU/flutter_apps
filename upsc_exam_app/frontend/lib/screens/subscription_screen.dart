// Subscription Screen
// Shows available subscription plans and allows users to upgrade

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  String _currentSubscription = 'none';

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  // Load current user's subscription type
  Future<void> _loadCurrentSubscription() async {
    final userData = await ApiService.getUserData();
    setState(() {
      _currentSubscription = userData['subscriptionType'] ?? 'none';
    });
  }

  // Show confirmation dialog before upgrading
  Future<void> _showUpgradeDialog(
    String planName,
    String subscriptionType,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Plan Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to change to $planName?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changing your plan will remove all your enrolled courses and bookmarked videos. You will need to re-enroll.',
                      style: TextStyle(fontSize: 13, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Change Plan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _upgradeSubscription(subscriptionType, planName);
    }
  }

  // Call API to upgrade subscription
  Future<void> _upgradeSubscription(
    String subscriptionType,
    String planName,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.upgradeSubscription(subscriptionType);

      setState(() {
        _currentSubscription = subscriptionType;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan changed to $planName! Your enrolled courses and bookmarks have been cleared.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlock premium content and features',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Current Subscription Badge
                  if (_currentSubscription != 'none')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Current Plan: ${_formatSubscriptionType(_currentSubscription)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_currentSubscription != 'none')
                    const SizedBox(height: 24),

                  // Plus Plan Card
                  _buildPlanCard(
                    title: 'Plus',
                    price: '₹24,999',
                    period: 'per year',
                    features: [
                      'Access to ALL courses',
                      'ALL test series included',
                      'Daily current affairs',
                      'Community access',
                      'Priority support',
                      'Offline downloads',
                      'Ad-free experience',
                    ],
                    color: Colors.purple,
                    subscriptionType: 'plus',
                    isRecommended: true,
                    isCurrent: _currentSubscription == 'plus',
                  ),
                  const SizedBox(height: 16),

                  // Individual Course Plan Card
                  _buildPlanCard(
                    title: 'Individual Course',
                    price: '₹2,499',
                    period: 'per course',
                    features: [
                      'Access to ONE course',
                      'All course materials',
                      'Community access',
                      'Email support',
                    ],
                    color: Colors.blue,
                    subscriptionType: 'individual',
                    isCurrent: _currentSubscription == 'individual',
                  ),
                  const SizedBox(height: 16),

                  // Test Series Plan Card
                  _buildPlanCard(
                    title: 'Test Series',
                    price: '₹4,999',
                    period: 'per year',
                    features: [
                      'Access to ALL test series',
                      'Practice questions',
                      'Detailed solutions',
                      'Performance analytics',
                      'Email support',
                    ],
                    color: Colors.orange,
                    subscriptionType: 'test-series',
                    isCurrent: _currentSubscription == 'test-series',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // Build a subscription plan card
  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required Color color,
    required String subscriptionType,
    bool isRecommended = false,
    bool isCurrent = false,
  }) {
    return Card(
      elevation: isRecommended ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRecommended
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recommended badge
            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (isRecommended) const SizedBox(height: 12),

            // Plan Title
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Text(
              period,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Features list
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subscribe button
            ElevatedButton(
              onPressed: isCurrent
                  ? null
                  : () => _showUpgradeDialog(title, subscriptionType),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.grey : color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isCurrent ? 'Current Plan' : 'Subscribe Now',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format subscription type for display
  String _formatSubscriptionType(String type) {
    switch (type) {
      case 'plus':
        return 'Plus';
      case 'individual':
        return 'Individual Course';
      case 'test-series':
        return 'Test Series';
      default:
        return 'None';
    }
  }
}
