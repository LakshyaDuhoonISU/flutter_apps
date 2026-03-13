// Student Test Screen
// Allows students to view and take tests

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/test_service.dart';
import '../models/test_model.dart';
import '../models/question_model.dart';
import '../models/test_result_model.dart';
import 'test_history_screen.dart';

// Test List Screen
class StudentTestScreen extends StatefulWidget {
  const StudentTestScreen({Key? key}) : super(key: key);

  @override
  State<StudentTestScreen> createState() => _StudentTestScreenState();
}

class _StudentTestScreenState extends State<StudentTestScreen> {
  late Future<List<TestModel>> _testsFuture;

  @override
  void initState() {
    super.initState();
    _testsFuture = TestService.getAllTests();
  }

  Future<void> _refreshTests() async {
    setState(() {
      _testsFuture = TestService.getAllTests();
    });
  }

  void _startTest(TestModel test) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => TestTakingScreen(test: test)),
        )
        .then((_) {
          if (mounted) _refreshTests();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Series'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TestHistoryScreen(),
                ),
              );
            },
            tooltip: 'Test History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<TestModel>>(
        future: _testsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshTests,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final tests = snapshot.data ?? [];

          if (tests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tests available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    test.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (test.description.isNotEmpty)
                        Text(
                          test.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${test.durationMinutes} min'),
                          const SizedBox(width: 16),
                          Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${test.totalQuestions} questions'),
                          const SizedBox(width: 16),
                          Icon(Icons.score, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${test.totalMarks} marks'),
                        ],
                      ),
                      if (test.isFree)
                        const Text(
                          'FREE',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _startTest(test),
                    child: const Text('Start'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Test Taking Screen
class TestTakingScreen extends StatefulWidget {
  final TestModel test;

  const TestTakingScreen({Key? key, required this.test}) : super(key: key);

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  List<Question> _questions = [];
  Map<String, int> _answers = {}; // questionId -> selectedOption
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  late int _remainingSeconds;
  Timer? _timer;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.test.durationMinutes * 60;
    _startTime = DateTime.now();
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await TestService.getTestDetails(widget.test.id);
      if (!mounted) return;
      setState(() {
        _questions = data['questions'] as List<Question>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading test: $e')));
        Navigator.of(context).pop();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _autoSubmitTest();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(int optionIndex) {
    setState(() {
      _answers[_questions[_currentQuestionIndex].id] = optionIndex;
    });
  }

  void _navigateToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _navigateToQuestion(_currentQuestionIndex + 1);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _navigateToQuestion(_currentQuestionIndex - 1);
    }
  }

  Future<void> _submitTest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Test'),
        content: Text(
          'You have answered ${_answers.length} out of ${_questions.length} questions.\n\n'
          'Are you sure you want to submit?',
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

    if (confirm == true) {
      await _performSubmission();
    }
  }

  Future<void> _autoSubmitTest() async {
    if (_isSubmitting) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time up! Submitting test...')),
    );

    await _performSubmission();
  }

  Future<void> _performSubmission() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final totalTimeTaken = DateTime.now().difference(_startTime!).inSeconds;

      // Format answers for API
      final answersList = _questions.map((q) {
        return {
          'questionId': q.id,
          'selectedOption': _answers[q.id] ?? -1,
          'timeTaken': 0,
        };
      }).toList();

      final result = await TestService.submitTestAttempt(
        testId: widget.test.id,
        answers: answersList,
        totalTimeTaken: totalTimeTaken,
      );

      if (mounted) {
        _timer?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                TestResultDisplayScreen(result: result, testId: widget.test.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting test: $e')));
      }
    }
  }

  void _showQuestionPalette() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Question Palette'),
        content: SizedBox(
          width: 400,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final question = _questions[index];
              final isAnswered = _answers.containsKey(question.id);
              final isCurrent = index == _currentQuestionIndex;

              return InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToQuestion(index);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.blue
                        : isAnswered
                        ? Colors.green
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent || isAnswered
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.test.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.test.title)),
        body: const Center(child: Text('No questions in this test')),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final selectedAnswer = _answers[question.id];

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
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
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.test.title),
              Text(
                'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            // Timer
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 300 ? Colors.red : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: _remainingSeconds < 300
                          ? Colors.white
                          : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        color: _remainingSeconds < 300
                            ? Colors.white
                            : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: _showQuestionPalette,
              tooltip: 'Question Palette',
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: _answers.length / _questions.length,
              minHeight: 6,
            ),

            // Question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Options
                    ...question.options.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final option = entry.value;
                      final isSelected = selectedAnswer == idx;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _selectAnswer(idx),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + idx),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            // Navigation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentQuestionIndex > 0
                          ? _previousQuestion
                          : null,
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_currentQuestionIndex < _questions.length - 1)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        child: const Text('Next'),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit Test'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Test Result Display Screen
class TestResultDisplayScreen extends StatelessWidget {
  final TestResult result;
  final String testId;

  const TestResultDisplayScreen({
    Key? key,
    required this.result,
    required this.testId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accuracy = double.tryParse(result.accuracy.toString()) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Result'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Score Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 64,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Test Completed!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Score
                    Text(
                      '${result.score}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'Score',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),

                    const SizedBox(height: 24),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          icon: Icons.check_circle,
                          color: Colors.green,
                          label: 'Correct',
                          value: '${result.correctCount}',
                        ),
                        _StatItem(
                          icon: Icons.cancel,
                          color: Colors.red,
                          label: 'Wrong',
                          value: '${result.wrongCount}',
                        ),
                        _StatItem(
                          icon: Icons.remove_circle,
                          color: Colors.orange,
                          label: 'Skipped',
                          value: '${result.unattemptedCount}',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Accuracy
                    LinearProgressIndicator(
                      value: accuracy / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        accuracy >= 75
                            ? Colors.green
                            : accuracy >= 50
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accuracy: ${accuracy.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const TestHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('View Test History'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatItem({
    Key? key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
