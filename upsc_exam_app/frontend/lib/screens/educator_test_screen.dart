// Educator Test Screen
// Allows educators to create, edit, and delete test series

import 'package:flutter/material.dart';
import '../services/test_service.dart';
import '../models/test_model.dart';
import '../models/question_model.dart';

class EducatorTestScreen extends StatefulWidget {
  const EducatorTestScreen({Key? key}) : super(key: key);

  @override
  State<EducatorTestScreen> createState() => _EducatorTestScreenState();
}

class _EducatorTestScreenState extends State<EducatorTestScreen> {
  late Future<List<TestModel>> _testsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testsFuture = TestService.getMyTests();
  }

  // Refresh tests
  Future<void> _refreshTests() async {
    setState(() {
      _testsFuture = TestService.getMyTests();
    });
  }

  // Show add/edit test dialog
  Future<void> _showTestDialog({TestModel? test}) async {
    final titleController = TextEditingController(text: test?.title ?? '');
    final descriptionController = TextEditingController(
      text: test?.description ?? '',
    );
    final durationController = TextEditingController(
      text: test?.durationMinutes.toString() ?? '60',
    );
    final marksController = TextEditingController(
      text: test?.totalMarks.toString() ?? '100',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(test == null ? 'Create Test' : 'Edit Test'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Test Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: marksController,
                    decoration: const InputDecoration(
                      labelText: 'Total Marks',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Test series are available for Plus and Test Series subscribers only.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    durationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill required fields'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final duration = int.tryParse(durationController.text.trim()) ?? 60;
        final marks = int.tryParse(marksController.text.trim()) ?? 100;

        if (test == null) {
          // Create new test
          await TestService.createTest(
            title: titleController.text.trim(),
            description: descriptionController.text.trim(),
            durationMinutes: duration,
            totalMarks: marks,
            isFree: false,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Test created successfully')),
            );
          }
        } else {
          // Update test
          await TestService.updateTest(
            testId: test.id,
            title: titleController.text.trim(),
            description: descriptionController.text.trim(),
            durationMinutes: duration,
            totalMarks: marks,
            isFree: false,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Test updated successfully')),
            );
          }
        }

        await _refreshTests();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    marksController.dispose();
  }

  // Delete test
  Future<void> _deleteTest(TestModel test) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test'),
        content: const Text(
          'Are you sure you want to delete this test? All questions will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await TestService.deleteTest(test.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test deleted successfully')),
          );
        }
        await _refreshTests();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Navigate to manage questions screen
  void _manageQuestions(TestModel test) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ManageQuestionsScreen(test: test),
          ),
        )
        .then((_) => _refreshTests());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Test Series'),
        actions: [
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
                    'No tests yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first test',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ListView.builder(
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
                          Text(
                            '${test.totalQuestions} questions • ${test.durationMinutes} min • ${test.totalMarks} marks',
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
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'manage',
                            child: Row(
                              children: [
                                Icon(Icons.list),
                                SizedBox(width: 8),
                                Text('Manage Questions'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'manage') {
                            _manageQuestions(test);
                          } else if (value == 'edit') {
                            _showTestDialog(test: test);
                          } else if (value == 'delete') {
                            _deleteTest(test);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTestDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Create Test'),
      ),
    );
  }
}

// Manage Questions Screen
class ManageQuestionsScreen extends StatefulWidget {
  final TestModel test;

  const ManageQuestionsScreen({Key? key, required this.test}) : super(key: key);

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> {
  late Future<Map<String, dynamic>> _testDetailsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testDetailsFuture = TestService.getTestDetails(widget.test.id);
  }

  // Refresh questions
  Future<void> _refreshQuestions() async {
    setState(() {
      _testDetailsFuture = TestService.getTestDetails(widget.test.id);
    });
  }

  // Show add/edit question dialog
  Future<void> _showQuestionDialog({Question? question}) async {
    final questionController = TextEditingController(
      text: question?.question ?? '',
    );
    final option1Controller = TextEditingController(
      text: question?.options.isNotEmpty == true ? question!.options[0] : '',
    );
    final option2Controller = TextEditingController(
      text: (question?.options.length ?? 0) > 1 ? question!.options[1] : '',
    );
    final option3Controller = TextEditingController(
      text: (question?.options.length ?? 0) > 2 ? question!.options[2] : '',
    );
    final option4Controller = TextEditingController(
      text: (question?.options.length ?? 0) > 3 ? question!.options[3] : '',
    );
    final explanationController = TextEditingController(
      text: question?.explanation ?? '',
    );
    final marksController = TextEditingController(
      text: question?.marks.toString() ?? '1',
    );

    int correctAnswer = question?.correctAnswer ?? 0;
    String difficulty = question?.difficulty ?? 'Medium';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(question == null ? 'Add Question' : 'Edit Question'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration: const InputDecoration(
                      labelText: 'Question',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: option1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Option 1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: option2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Option 2',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: option3Controller,
                    decoration: const InputDecoration(
                      labelText: 'Option 3',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: option4Controller,
                    decoration: const InputDecoration(
                      labelText: 'Option 4',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: correctAnswer,
                    decoration: const InputDecoration(
                      labelText: 'Correct Answer',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Option 1')),
                      DropdownMenuItem(value: 1, child: Text('Option 2')),
                      DropdownMenuItem(value: 2, child: Text('Option 3')),
                      DropdownMenuItem(value: 3, child: Text('Option 4')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        correctAnswer = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: marksController,
                          decoration: const InputDecoration(
                            labelText: 'Marks',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: difficulty,
                          decoration: const InputDecoration(
                            labelText: 'Difficulty',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Easy',
                              child: Text('Easy'),
                            ),
                            DropdownMenuItem(
                              value: 'Medium',
                              child: Text('Medium'),
                            ),
                            DropdownMenuItem(
                              value: 'Hard',
                              child: Text('Hard'),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              difficulty = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: explanationController,
                    decoration: const InputDecoration(
                      labelText: 'Explanation',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (questionController.text.trim().isEmpty ||
                    option1Controller.text.trim().isEmpty ||
                    option2Controller.text.trim().isEmpty ||
                    option3Controller.text.trim().isEmpty ||
                    option4Controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all options')),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final options = [
          option1Controller.text.trim(),
          option2Controller.text.trim(),
          option3Controller.text.trim(),
          option4Controller.text.trim(),
        ];
        final marks = int.tryParse(marksController.text.trim()) ?? 1;

        if (question == null) {
          // Add new question
          await TestService.addQuestionToTest(
            testId: widget.test.id,
            question: questionController.text.trim(),
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanationController.text.trim(),
            difficulty: difficulty,
            marks: marks,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Question added successfully')),
            );
          }
        } else {
          // Update question
          await TestService.updateQuestion(
            testId: widget.test.id,
            questionId: question.id,
            question: questionController.text.trim(),
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanationController.text.trim(),
            difficulty: difficulty,
            marks: marks,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Question updated successfully')),
            );
          }
        }

        await _refreshQuestions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    questionController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    option3Controller.dispose();
    option4Controller.dispose();
    explanationController.dispose();
    marksController.dispose();
  }

  // Delete question
  Future<void> _deleteQuestion(Question question) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await TestService.deleteQuestion(
          testId: widget.test.id,
          questionId: question.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question deleted successfully')),
          );
        }
        await _refreshQuestions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshQuestions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _testDetailsFuture,
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
                    onPressed: _refreshQuestions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final questions =
              snapshot.data?['questions'] as List<Question>? ?? [];

          if (questions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add questions to this test',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(
                        'Q${index + 1}. ${question.question}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${question.difficulty} • ${question.marks} mark(s)',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Options:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...question.options.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final option = entry.value;
                                final isCorrect = idx == question.correctAnswer;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${idx + 1}. $option',
                                          style: TextStyle(
                                            color: isCorrect
                                                ? Colors.green
                                                : null,
                                            fontWeight: isCorrect
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isCorrect)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              if (question.explanation?.isNotEmpty == true) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Explanation:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(question.explanation ?? ''),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        _showQuestionDialog(question: question),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _deleteQuestion(question),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuestionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
      ),
    );
  }
}
