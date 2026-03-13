// Educator PYQ Screen
// Allows educators to create, edit, and delete Previous Year Question Sets

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pyq_service.dart';
import '../models/pyq_set_model.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';

class EducatorPyqScreen extends StatefulWidget {
  const EducatorPyqScreen({Key? key}) : super(key: key);

  @override
  State<EducatorPyqScreen> createState() => _EducatorPyqScreenState();
}

class _EducatorPyqScreenState extends State<EducatorPyqScreen> {
  late Future<List<PYQSet>> _pyqSetsFuture;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _refreshPYQSets();
  }

  // Load courses
  Future<void> _loadCourses() async {
    try {
      final courses = await CourseService.getAllCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
      });
    } catch (e) {
      print('Error loading courses: $e');
    }
  }

  // Refresh PYQ sets list
  void _refreshPYQSets() {
    setState(() {
      _pyqSetsFuture = PyqService.getAllPYQSets();
    });
  }

  // Navigate to create/edit PYQ set screen
  void _createPYQSet() async {
    if (_courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a course first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePYQSetScreen(courses: _courses),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      _refreshPYQSets();
    }
  }

  // Navigate to edit PYQ set screen
  void _editPYQSet(PYQSet pyqSet) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreatePYQSetScreen(courses: _courses, pyqSet: pyqSet),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      _refreshPYQSets();
    }
  }

  // Delete PYQ set
  Future<void> _deletePYQSet(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PYQ Set'),
        content: const Text(
          'Are you sure you want to delete this PYQ set? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PyqService.deletePYQSet(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PYQ set deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshPYQSets();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage PYQ Sets'), centerTitle: true),
      body: FutureBuilder<List<PYQSet>>(
        future: _pyqSetsFuture,
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
                    onPressed: _refreshPYQSets,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final pyqSets = snapshot.data ?? [];

          if (pyqSets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No PYQ sets yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first PYQ set',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pyqSets.length,
            itemBuilder: (context, index) {
              final pyqSet = pyqSets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      pyqSet.year.toString().substring(2),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    pyqSet.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Subject: ${pyqSet.subject}'),
                      Text(
                        '${pyqSet.totalQuestions} Questions • ${pyqSet.totalMarks} Marks',
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPYQSet(pyqSet),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePYQSet(pyqSet.id!),
                      ),
                    ],
                  ),
                  onTap: () => _editPYQSet(pyqSet),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPYQSet,
        icon: const Icon(Icons.add),
        label: const Text('Create PYQ Set'),
      ),
    );
  }
}

// Create/Edit PYQ Set Screen
class CreatePYQSetScreen extends StatefulWidget {
  final List<Course> courses;
  final PYQSet? pyqSet;

  const CreatePYQSetScreen({Key? key, required this.courses, this.pyqSet})
    : super(key: key);

  @override
  State<CreatePYQSetScreen> createState() => _CreatePYQSetScreenState();
}

class _CreatePYQSetScreenState extends State<CreatePYQSetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCourseId;
  List<PyqQuestionWidget> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing
    if (widget.pyqSet != null) {
      _titleController.text = widget.pyqSet!.title;
      _yearController.text = widget.pyqSet!.year.toString();
      _subjectController.text = widget.pyqSet!.subject;
      _descriptionController.text = widget.pyqSet!.description;
      _selectedCourseId = widget.pyqSet!.courseId;

      // Load existing questions
      _questions = widget.pyqSet!.questions.map((q) {
        return PyqQuestionWidget(
          questionController: TextEditingController(text: q.question),
          optionControllers: q.options
              .map((opt) => TextEditingController(text: opt))
              .toList(),
          explanationController: TextEditingController(text: q.explanation),
          correctAnswer: q.correctAnswer,
          difficulty: q.difficulty,
          marks: q.marks,
        );
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    for (var q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  // Add new question
  void _addQuestion() {
    setState(() {
      _questions.add(
        PyqQuestionWidget(
          questionController: TextEditingController(),
          optionControllers: List.generate(4, (_) => TextEditingController()),
          explanationController: TextEditingController(),
          correctAnswer: 0,
          difficulty: 'Medium',
          marks: 1,
        ),
      );
    });
  }

  // Remove question
  void _removeQuestion(int index) {
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  // Submit PYQ set
  Future<void> _submitPYQSet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all questions
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill question ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      for (var j = 0; j < 4; j++) {
        if (q.optionControllers[j].text.isEmpty) {
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
      // Prepare questions data
      final questionsData = _questions
          .map(
            (q) => PYQQuestion(
              question: q.questionController.text,
              options: q.optionControllers.map((c) => c.text).toList(),
              correctAnswer: q.correctAnswer,
              explanation: q.explanationController.text,
              difficulty: q.difficulty,
              marks: q.marks,
            ),
          )
          .toList();

      // Create or update PYQ set
      if (widget.pyqSet == null) {
        await PyqService.createPYQSet(
          title: _titleController.text,
          year: int.parse(_yearController.text),
          subject: _subjectController.text,
          courseId: _selectedCourseId!,
          questions: questionsData,
          description: _descriptionController.text,
        );
      } else {
        await PyqService.updatePYQSet(
          id: widget.pyqSet!.id!,
          title: _titleController.text,
          year: int.parse(_yearController.text),
          subject: _subjectController.text,
          description: _descriptionController.text,
          questions: questionsData,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.pyqSet == null
                  ? 'PYQ set created successfully!'
                  : 'PYQ set updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pyqSet == null ? 'Create PYQ Set' : 'Edit PYQ Set'),
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
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g., 2024 Polity PYQ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Year and Subject row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            decoration: const InputDecoration(
                              labelText: 'Year *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final year = int.tryParse(value);
                              if (year == null || year < 1900 || year > 2100) {
                                return 'Invalid year';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText: 'Subject *',
                              hintText: 'Polity, History, etc.',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.book),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Course dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Course *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      items: widget.courses.map((course) {
                        return DropdownMenuItem(
                          value: course.id,
                          child: Text(course.title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourseId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a course';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Add any notes or instructions...',
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // Questions section header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Questions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Questions list
                    if (_questions.isEmpty)
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
                                'No questions yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(_questions.length, (index) {
                        return _buildQuestionCard(index);
                      }),

                    const SizedBox(height: 24),

                    // Submit button
                    ElevatedButton(
                      onPressed: _submitPYQSet,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                      ),
                      child: Text(
                        widget.pyqSet == null
                            ? 'Create PYQ Set'
                            : 'Update PYQ Set',
                        style: const TextStyle(
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

  // Build question card
  Widget _buildQuestionCard(int index) {
    final question = _questions[index];

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
                  onPressed: () => _removeQuestion(index),
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
              maxLines: 3,
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

            // Difficulty and Marks row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: question.difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['Easy', 'Medium', 'Hard']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        question.difficulty = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: question.marks.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Marks',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      question.marks = int.tryParse(value) ?? 1;
                    },
                  ),
                ),
              ],
            ),

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

// Question widget model
class PyqQuestionWidget {
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final TextEditingController explanationController;
  int correctAnswer;
  String difficulty;
  int marks;

  PyqQuestionWidget({
    required this.questionController,
    required this.optionControllers,
    required this.explanationController,
    required this.correctAnswer,
    required this.difficulty,
    required this.marks,
  });

  void dispose() {
    questionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
    explanationController.dispose();
  }
}
