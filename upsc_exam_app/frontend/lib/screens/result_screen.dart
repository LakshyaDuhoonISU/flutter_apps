// Result Screen
// Displays test results with detailed analysis

import 'package:flutter/material.dart';
import '../models/test_result_model.dart';
import '../models/question_model.dart';

class ResultScreen extends StatelessWidget {
  final TestResult testResult;
  final List<Question> questions;

  const ResultScreen({
    Key? key,
    required this.testResult,
    required this.questions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a map of questionId -> Question for easy lookup
    final questionMap = {for (var q in questions) q.id: q};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Your Score',
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${testResult.score}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accuracy: ${testResult.accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Statistics cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Correct',
                      testResult.correctCount.toString(),
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Wrong',
                      testResult.wrongCount.toString(),
                      Colors.red,
                      Icons.cancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Unattempted',
                      testResult.unattemptedCount.toString(),
                      Colors.orange,
                      Icons.remove_circle,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Question-wise analysis header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Text(
                'Question-wise Analysis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // Question-wise results
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: testResult.answers.length,
              itemBuilder: (context, index) {
                final answer = testResult.answers[index];
                final question = questionMap[answer.questionId];

                if (question == null) return const SizedBox.shrink();

                return _buildQuestionResultCard(index + 1, question, answer);
              },
            ),

            const SizedBox(height: 24),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil(
                        (route) =>
                            route.isFirst || route.settings.name == '/home',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(fontSize: 16),
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

  // Build statistics card
  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Build question result card
  Widget _buildQuestionResultCard(
    int questionNumber,
    Question question,
    Answer answer,
  ) {
    final isCorrect = answer.isCorrect;
    final wasAttempted = answer.selectedOption != -1;
    Color cardColor;
    IconData statusIcon;

    if (!wasAttempted) {
      cardColor = Colors.orange[50]!;
      statusIcon = Icons.remove_circle;
    } else if (isCorrect) {
      cardColor = Colors.green[50]!;
      statusIcon = Icons.check_circle;
    } else {
      cardColor = Colors.red[50]!;
      statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Icon(statusIcon, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Question $questionNumber',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(question.difficulty),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    question.difficulty,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Question text
            Text(question.question, style: const TextStyle(fontSize: 15)),

            const SizedBox(height: 12),

            // Options
            ...question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final optionText = entry.value;
              final isCorrectOption = optionIndex == question.correctAnswer;
              final isSelectedOption = optionIndex == answer.selectedOption;

              Color? optionColor;
              if (isSelectedOption && !isCorrect) {
                optionColor = Colors.red[100];
              } else if (isCorrectOption) {
                optionColor = Colors.green[100];
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: optionColor,
                  border: Border.all(
                    color: isCorrectOption
                        ? Colors.green
                        : (isSelectedOption ? Colors.red : Colors.grey[300]!),
                    width: isCorrectOption || isSelectedOption ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      '${String.fromCharCode(65 + optionIndex)}.',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        optionText,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (isCorrectOption)
                      const Icon(Icons.check, color: Colors.green, size: 20),
                    if (isSelectedOption && !isCorrect)
                      const Icon(Icons.close, color: Colors.red, size: 20),
                  ],
                ),
              );
            }).toList(),

            // Explanation
            if (question.explanation != null &&
                question.explanation!.isNotEmpty) ...[
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
                    const Text(
                      'Explanation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.explanation!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Get color based on difficulty
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
