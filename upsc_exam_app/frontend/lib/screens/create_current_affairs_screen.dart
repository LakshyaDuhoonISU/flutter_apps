// Create Current Affairs Screen
// Allows educators to create daily current affairs digest with quiz

import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';

class CreateCurrentAffairsScreen extends StatefulWidget {
  const CreateCurrentAffairsScreen({Key? key}) : super(key: key);

  @override
  State<CreateCurrentAffairsScreen> createState() =>
      _CreateCurrentAffairsScreenState();
}

class _CreateCurrentAffairsScreenState
    extends State<CreateCurrentAffairsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');

  List<QuizQuestion> _quizQuestions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // Add new quiz question
  void _addQuizQuestion() {
    setState(() {
      _quizQuestions.add(
        QuizQuestion(
          questionController: TextEditingController(),
          optionControllers: List.generate(4, (_) => TextEditingController()),
          correctAnswer: 0,
          explanationController: TextEditingController(),
        ),
      );
    });
  }

  // Remove quiz question
  void _removeQuizQuestion(int index) {
    setState(() {
      _quizQuestions[index].dispose();
      _quizQuestions.removeAt(index);
    });
  }

  // Submit current affairs
  Future<void> _submitCurrentAffairs() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate quiz questions
    for (var i = 0; i < _quizQuestions.length; i++) {
      if (_quizQuestions[i].questionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill question ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      for (var j = 0; j < 4; j++) {
        if (_quizQuestions[i].optionControllers[j].text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please fill all options for question ${i + 1}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare quiz data
      final quizData = _quizQuestions
          .map(
            (q) => {
              'question': q.questionController.text,
              'options': q.optionControllers.map((c) => c.text).toList(),
              'correctAnswer': q.correctAnswer,
              'explanation': q.explanationController.text,
            },
          )
          .toList();

      // Create current affairs
      final response = await ApiService.post('/current-affairs', {
        'date': DateTime.now().toIso8601String(),
        'title': _titleController.text,
        'summary': _summaryController.text,
        'category': _categoryController.text,
        'quiz': quizData,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Current affairs created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to create current affairs');
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
        title: const Text('Create Current Affairs'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info card
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Creating new current affairs will replace the previous one.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Category
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Summary
                    TextFormField(
                      controller: _summaryController,
                      decoration: const InputDecoration(
                        labelText: 'Summary *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Write a detailed summary...',
                      ),
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a summary';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Quiz section header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quiz Questions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addQuizQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Quiz questions
                    if (_quizQuestions.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.quiz,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No quiz questions yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(_quizQuestions.length, (index) {
                        return _buildQuizQuestionCard(index);
                      }),

                    const SizedBox(height: 24),

                    // Submit button
                    ElevatedButton(
                      onPressed: _submitCurrentAffairs,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Create Current Affairs',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Build quiz question card
  Widget _buildQuizQuestionCard(int index) {
    final question = _quizQuestions[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeQuizQuestion(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Question text
            TextFormField(
              controller: question.questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Options
            const Text(
              'Options:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...List.generate(4, (optionIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: optionIndex,
                      groupValue: question.correctAnswer,
                      onChanged: (value) {
                        setState(() {
                          question.correctAnswer = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: question.optionControllers[optionIndex],
                        decoration: InputDecoration(
                          labelText:
                              '${String.fromCharCode(65 + optionIndex)}.',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // Explanation
            TextFormField(
              controller: question.explanationController,
              decoration: const InputDecoration(
                labelText: 'Explanation (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// Quiz question model
class QuizQuestion {
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  int correctAnswer;
  final TextEditingController explanationController;

  QuizQuestion({
    required this.questionController,
    required this.optionControllers,
    required this.correctAnswer,
    required this.explanationController,
  });

  void dispose() {
    questionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
    explanationController.dispose();
  }
}
