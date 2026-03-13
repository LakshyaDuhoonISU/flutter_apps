// Question Card Widget
// Displays a single question with options

import 'package:flutter/material.dart';
import '../models/question_model.dart';
import 'answer_option.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final int? selectedOption; // Currently selected option (0-3)
  final Function(int) onAnswerSelected;

  const QuestionCard({
    Key? key,
    required this.question,
    this.selectedOption,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Difficulty badge
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(question.difficulty),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  question.difficulty,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Question text
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Answer options
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final optionText = entry.value;

              return AnswerOption(
                optionIndex: index,
                optionText: optionText,
                isSelected: selectedOption == index,
                onTap: () => onAnswerSelected(index),
              );
            }).toList(),

            const SizedBox(height: 16),

            // Marks info
            Row(
              children: [
                const Icon(Icons.score, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Marks: ${question.marks}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
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
