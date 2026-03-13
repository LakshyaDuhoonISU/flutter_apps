// Current Affairs Screen
// Displays today's current affairs with quiz

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'create_current_affairs_screen.dart';

class CurrentAffairsScreen extends StatefulWidget {
  const CurrentAffairsScreen({Key? key}) : super(key: key);

  @override
  State<CurrentAffairsScreen> createState() => _CurrentAffairsScreenState();
}

class _CurrentAffairsScreenState extends State<CurrentAffairsScreen> {
  late Future<Map<String, dynamic>> _currentAffairsFuture;
  Map<int, int> _selectedAnswers = {}; // questionIndex -> selectedOptionIndex
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _currentAffairsFuture = _fetchCurrentAffairs();
    _loadUserRole();
  }

  // Load user role from SharedPreferences
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userRole = prefs.getString(userRoleKey) ?? 'student';
    });
  }

  // Refresh current affairs
  Future<void> _refreshCurrentAffairs() async {
    setState(() {
      _selectedAnswers = {}; // Reset quiz answers
      _currentAffairsFuture = _fetchCurrentAffairs();
    });
  }

  // Fetch today's current affairs
  Future<Map<String, dynamic>> _fetchCurrentAffairs() async {
    try {
      final response = await ApiService.get('/current-affairs/today');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Check if data is null
        if (data['data'] == null) {
          // Return empty structure if no data available
          return {
            'title': 'No Current Affairs Available',
            'summary':
                'No current affairs content has been published yet. Please check back later.',
            'quiz': [],
          };
        }
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load current affairs');
      }
    } catch (e) {
      throw Exception('Error loading current affairs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Affairs'), centerTitle: true),
      floatingActionButton: _userRole == 'educator'
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateCurrentAffairsScreen(),
                  ),
                );
                // Refresh if current affairs was created
                if (result == true) {
                  _refreshCurrentAffairs();
                }
              },
              backgroundColor: Colors.deepOrange,
              child: const Icon(Icons.add),
            )
          : null,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _currentAffairsFuture,
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
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Success state
          final data = snapshot.data!;
          final title = data['title'] ?? 'Current Affairs';
          final summary = data['summary'] ?? 'No content available';
          final quiz = data['quiz'] as List? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Summary
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(summary, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quiz section
                if (quiz.isNotEmpty) ...[
                  const Text(
                    'Daily Quiz',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...quiz.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return _buildQuizCard(index, question);
                  }).toList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Build quiz question card
  Widget _buildQuizCard(int questionIndex, Map<String, dynamic> question) {
    final questionText = question['question'] ?? '';
    final options = question['options'] as List? ?? [];
    final correctAnswer = question['correctAnswer'] ?? 0;
    final explanation = question['explanation'] ?? '';
    final selectedAnswer = _selectedAnswers[questionIndex];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${questionIndex + 1}: $questionText',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final optionText = entry.value;

              // Determine the color and icon for this option
              Color? backgroundColor;
              Color? borderColor;
              IconData? icon;

              if (selectedAnswer != null) {
                // After selection, show correct answer in green
                if (optionIndex == correctAnswer) {
                  backgroundColor = Colors.green[50];
                  borderColor = Colors.green;
                  icon = Icons.check_circle;
                }
                // Show selected wrong answer in red
                else if (optionIndex == selectedAnswer) {
                  backgroundColor = Colors.red[50];
                  borderColor = Colors.red;
                  icon = Icons.cancel;
                }
              }

              return GestureDetector(
                onTap: selectedAnswer == null
                    ? () {
                        setState(() {
                          _selectedAnswers[questionIndex] = optionIndex;
                        });
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Colors.grey[50],
                    border: Border.all(
                      color: borderColor ?? Colors.grey[300]!,
                      width: selectedAnswer == null ? 1 : 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${String.fromCharCode(65 + optionIndex)}. $optionText',
                          style: TextStyle(
                            fontSize: 14,
                            color: borderColor ?? Colors.black87,
                            fontWeight:
                                selectedAnswer != null &&
                                    (optionIndex == correctAnswer ||
                                        optionIndex == selectedAnswer)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (icon != null)
                        Icon(icon, color: borderColor, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
            // Show explanation only after an answer is selected
            if (selectedAnswer != null && explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Explanation:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(explanation, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
