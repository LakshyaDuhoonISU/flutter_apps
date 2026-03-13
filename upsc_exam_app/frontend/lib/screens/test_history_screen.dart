// Test History Screen
// Displays student's test attempt history

import 'package:flutter/material.dart';
import '../services/test_service.dart';
import '../models/test_result_model.dart';
import '../models/question_model.dart';

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  late Future<List<TestResult>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = TestService.getTestHistory();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = TestService.getTestHistory();
    });
  }

  void _viewDetails(TestResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TestResultDetailScreen(resultId: result.id),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Parse as UTC if not already, then convert to local (IST) for display
    final local =
        (date.isUtc
                ? date
                : DateTime.utc(
                    date.year,
                    date.month,
                    date.day,
                    date.hour,
                    date.minute,
                    date.second,
                  ))
            .toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<TestResult>>(
        future: _historyFuture,
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
                    onPressed: _refreshHistory,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final results = snapshot.data ?? [];

          if (results.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No test history',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your test attempts will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              final accuracy =
                  double.tryParse(result.accuracy.toString()) ?? 0.0;
              final testTitle = result.testId is Map
                  ? (result.testId as Map<String, dynamic>)['title'] ??
                        'Unknown Test'
                  : 'Unknown Test';
              final attemptDate = result.attemptedAt;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _viewDetails(result),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                testTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getAccuracyColor(accuracy),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${accuracy.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(attemptDate),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ResultStat(
                              icon: Icons.score,
                              label: 'Score',
                              value: '${result.score}',
                              color: Colors.blue,
                            ),
                            _ResultStat(
                              icon: Icons.check_circle,
                              label: 'Correct',
                              value: '${result.correctCount}',
                              color: Colors.green,
                            ),
                            _ResultStat(
                              icon: Icons.cancel,
                              label: 'Wrong',
                              value: '${result.wrongCount}',
                              color: Colors.red,
                            ),
                            _ResultStat(
                              icon: Icons.remove_circle,
                              label: 'Skipped',
                              value: '${result.unattemptedCount}',
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        TextButton.icon(
                          onPressed: () => _viewDetails(result),
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Detailed Results'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 75) return Colors.green;
    if (accuracy >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultStat({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// Test Result Detail Screen
class TestResultDetailScreen extends StatefulWidget {
  final String resultId;

  const TestResultDetailScreen({Key? key, required this.resultId})
    : super(key: key);

  @override
  State<TestResultDetailScreen> createState() => _TestResultDetailScreenState();
}

class _TestResultDetailScreenState extends State<TestResultDetailScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = TestService.getTestResult(widget.resultId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Result Details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
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
                    onPressed: () => setState(() {
                      _detailsFuture = TestService.getTestResult(
                        widget.resultId,
                      );
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final result = data['result'] as TestResult;
          final questions = data['questions'] as List<Question>;
          final accuracy = double.tryParse(result.accuracy.toString()) ?? 0.0;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: Colors.blue.shade50,
                  child: Column(
                    children: [
                      Text(
                        '${result.score}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text(
                        'Your Score',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ResultStat(
                            icon: Icons.check_circle,
                            label: 'Correct',
                            value: '${result.correctCount}',
                            color: Colors.green,
                          ),
                          _ResultStat(
                            icon: Icons.cancel,
                            label: 'Wrong',
                            value: '${result.wrongCount}',
                            color: Colors.red,
                          ),
                          _ResultStat(
                            icon: Icons.remove_circle,
                            label: 'Skipped',
                            value: '${result.unattemptedCount}',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: accuracy >= 75
                              ? Colors.green
                              : accuracy >= 50
                              ? Colors.orange
                              : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Accuracy: ${accuracy.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Questions Review
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];

                    // Find user's answer from result.answers
                    final userAnswerData = result.answers.firstWhere(
                      (ans) => ans.questionId == question.id,
                      orElse: () => Answer(
                        questionId: question.id,
                        selectedOption: -1,
                        isCorrect: false,
                      ),
                    );

                    final userAnswer = userAnswerData.selectedOption;
                    final isCorrect = userAnswerData.isCorrect;
                    final isAttempted = userAnswer != -1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question header
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Question ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (!isAttempted)
                                  const Chip(
                                    label: Text('Skipped'),
                                    backgroundColor: Colors.orange,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                else if (isCorrect)
                                  const Chip(
                                    label: Text('Correct'),
                                    backgroundColor: Colors.green,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                else
                                  const Chip(
                                    label: Text('Wrong'),
                                    backgroundColor: Colors.red,
                                    labelStyle: TextStyle(color: Colors.white),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Question text
                            Text(
                              question.question,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),

                            // Options
                            ...question.options.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final option = entry.value;
                              final isUserAnswer = userAnswer == idx;
                              final isCorrectAnswer =
                                  question.correctAnswer == idx;

                              Color? backgroundColor;
                              Color? borderColor;
                              Icon? icon;

                              if (isCorrectAnswer) {
                                backgroundColor = Colors.green.shade50;
                                borderColor = Colors.green;
                                icon = const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                );
                              } else if (isUserAnswer && !isCorrect) {
                                backgroundColor = Colors.red.shade50;
                                borderColor = Colors.red;
                                icon = const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                );
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  border: Border.all(
                                    color: borderColor ?? Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: backgroundColor != null
                                            ? (isCorrectAnswer
                                                  ? Colors.green
                                                  : Colors.red)
                                            : Colors.grey.shade300,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          String.fromCharCode(65 + idx),
                                          style: TextStyle(
                                            color: backgroundColor != null
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(option)),
                                    if (icon != null) icon,
                                  ],
                                ),
                              );
                            }).toList(),

                            // Explanation
                            if (question.explanation?.isNotEmpty == true) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Explanation',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(question.explanation ?? ''),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
