// Test Screen
// Displays questions one by one and allows user to select answers

import 'package:flutter/material.dart';
import '../services/test_service.dart';
import '../models/test_model.dart';
import '../models/question_model.dart';
import '../widgets/question_card.dart';
import 'result_screen.dart';

class TestScreen extends StatefulWidget {
  final String testId;

  const TestScreen({Key? key, required this.testId}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late Future<Map<String, dynamic>> _testDataFuture;
  TestModel? _test;
  List<Question>? _questions;
  int _currentQuestionIndex = 0;
  Map<String, int> _selectedAnswers = {}; // questionId -> selectedOption
  bool _isSubmitting = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _testDataFuture = TestService.getTestById(widget.testId);
    _startTime = DateTime.now();
  }

  // Handle answer selection
  void _onAnswerSelected(String questionId, int selectedOption) {
    setState(() {
      _selectedAnswers[questionId] = selectedOption;
    });
  }

  // Navigate to next question
  void _nextQuestion() {
    if (_currentQuestionIndex < (_questions?.length ?? 0) - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  // Navigate to previous question
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  // Submit test
  Future<void> _submitTest() async {
    // Confirm submission
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Test'),
        content: Text(
          'You have answered ${_selectedAnswers.length} out of ${_questions?.length ?? 0} questions.\n\nAre you sure you want to submit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Calculate total time taken in minutes
      final timeTaken = _startTime != null
          ? DateTime.now().difference(_startTime!).inMinutes
          : 0;

      // Submit test
      final result = await TestService.submitTest(
        testId: widget.testId,
        answers: _selectedAnswers,
        totalTimeTaken: timeTaken,
      );

      // Navigate to result screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                ResultScreen(testResult: result, questions: _questions!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent accidental back navigation
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Test'),
            content: const Text(
              'Are you sure you want to exit? Your progress will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Test'), centerTitle: true),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _testDataFuture,
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
                    ),
                  ],
                ),
              );
            }

            // Success state - initialize data
            if (_test == null) {
              _test = snapshot.data!['test'] as TestModel;
              _questions = snapshot.data!['questions'] as List<Question>;
            }

            final currentQuestion = _questions![_currentQuestionIndex];

            return Column(
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions!.length,
                ),

                // Question counter
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${_questions!.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Answered: ${_selectedAnswers.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),

                // Question card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: QuestionCard(
                      question: currentQuestion,
                      selectedOption: _selectedAnswers[currentQuestion.id],
                      onAnswerSelected: (option) =>
                          _onAnswerSelected(currentQuestion.id, option),
                    ),
                  ),
                ),

                // Navigation buttons
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Previous button
                      if (_currentQuestionIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousQuestion,
                            child: const Text('Previous'),
                          ),
                        ),
                      if (_currentQuestionIndex > 0) const SizedBox(width: 12),

                      // Next or Submit button
                      Expanded(
                        child: _currentQuestionIndex < _questions!.length - 1
                            ? ElevatedButton(
                                onPressed: _nextQuestion,
                                child: const Text('Next'),
                              )
                            : ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitTest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Submit Test'),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
