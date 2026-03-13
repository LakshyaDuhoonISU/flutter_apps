// Student PYQ Screen
// Allows students to practice Previous Year Question Sets

import 'package:flutter/material.dart';
import '../services/pyq_service.dart';
import '../models/pyq_set_model.dart';

class StudentPyqScreen extends StatefulWidget {
  const StudentPyqScreen({Key? key}) : super(key: key);

  @override
  State<StudentPyqScreen> createState() => _StudentPyqScreenState();
}

class _StudentPyqScreenState extends State<StudentPyqScreen> {
  late Future<List<PYQSet>> _pyqSetsFuture;
  String? _selectedYear;
  String? _selectedSubject;
  List<String> _availableYears = [];
  List<String> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadPYQSets();
  }

  // Load PYQ sets
  Future<void> _loadPYQSets() async {
    setState(() {
      _pyqSetsFuture = PyqService.getAllPYQSets(
        year: _selectedYear != null ? int.tryParse(_selectedYear!) : null,
        subject: _selectedSubject,
      );
    });

    try {
      final pyqSets = await _pyqSetsFuture;
      if (!mounted) return;
      // Extract unique years and subjects
      final years = pyqSets.map((s) => s.year.toString()).toSet().toList();
      years.sort((a, b) => b.compareTo(a));
      final subjects = pyqSets.map((s) => s.subject).toSet().toList();
      subjects.sort();

      setState(() {
        _availableYears = years;
        _availableSubjects = subjects;
      });
    } catch (e) {
      print('Error loading PYQ sets: $e');
    }
  }

  // Show filters dialog
  Future<void> _showFiltersDialog() async {
    String? tempYear = _selectedYear;
    String? tempSubject = _selectedSubject;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter PYQ Sets'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                value: tempYear,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Years')),
                  ..._availableYears.map((year) {
                    return DropdownMenuItem(value: year, child: Text(year));
                  }).toList(),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    tempYear = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: tempSubject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Subjects'),
                  ),
                  ..._availableSubjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    tempSubject = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedYear = tempYear;
                  _selectedSubject = tempSubject;
                });
                _loadPYQSets();
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  // Open practice screen
  void _practicePYQSet(PYQSet pyqSet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticePYQSetScreen(pyqSet: pyqSet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PYQ Practice'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Badge(
              label: Text(
                (_selectedYear != null || _selectedSubject != null)
                    ? '${[_selectedYear, _selectedSubject].where((e) => e != null).length}'
                    : '',
              ),
              isLabelVisible: _selectedYear != null || _selectedSubject != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFiltersDialog,
          ),
        ],
      ),
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
                    onPressed: _loadPYQSets,
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
                    'No PYQ sets available',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later',
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
                child: InkWell(
                  onTap: () => _practicePYQSet(pyqSet),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                pyqSet.year.toString().substring(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pyqSet.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pyqSet.subject,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        if (pyqSet.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            pyqSet.description,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.quiz_outlined,
                              '${pyqSet.totalQuestions} Questions',
                            ),
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              Icons.score_outlined,
                              '${pyqSet.totalMarks} Marks',
                            ),
                          ],
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Practice PYQ Set Screen
class PracticePYQSetScreen extends StatefulWidget {
  final PYQSet pyqSet;

  const PracticePYQSetScreen({Key? key, required this.pyqSet})
    : super(key: key);

  @override
  State<PracticePYQSetScreen> createState() => _PracticePYQSetScreenState();
}

class _PracticePYQSetScreenState extends State<PracticePYQSetScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _showAnswer = false;
  List<int?> _userAnswers = [];
  int _score = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _userAnswers = List.filled(widget.pyqSet.questions.length, null);
  }

  // Get current question
  PYQQuestion get _currentQuestion =>
      widget.pyqSet.questions[_currentQuestionIndex];

  // Check answer
  void _checkAnswer() {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an answer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _showAnswer = true;
      _userAnswers[_currentQuestionIndex] = _selectedAnswer;
      if (_selectedAnswer == _currentQuestion.correctAnswer) {
        _score += _currentQuestion.marks;
      }
    });
  }

  // Next question
  void _nextQuestion() {
    if (_currentQuestionIndex < widget.pyqSet.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = _userAnswers[_currentQuestionIndex];
        _showAnswer = _userAnswers[_currentQuestionIndex] != null;
      });
    } else {
      _finishPractice();
    }
  }

  // Previous question
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswer = _userAnswers[_currentQuestionIndex];
        _showAnswer = _userAnswers[_currentQuestionIndex] != null;
      });
    }
  }

  // Finish practice
  void _finishPractice() {
    setState(() {
      _isCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildResultScreen();
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.pyqSet.title), centerTitle: true),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.pyqSet.questions.length,
            backgroundColor: Colors.grey[200],
          ),

          // Question info
          Container(
            color: Colors.blue[50],
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1}/${widget.pyqSet.questions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(_currentQuestion.difficulty),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _currentQuestion.difficulty,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        '${_currentQuestion.marks} marks',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.green[100],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question text
                  Text(
                    _currentQuestion.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Options
                  ...List.generate(
                    _currentQuestion.options.length,
                    (index) => _buildOptionCard(index),
                  ),

                  // Explanation (shown after answering)
                  if (_showAnswer &&
                      _currentQuestion.explanation.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Explanation',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentQuestion.explanation,
                            style: TextStyle(
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showAnswer ? _nextQuestion : _checkAnswer,
                    child: Text(
                      _showAnswer
                          ? (_currentQuestionIndex ==
                                    widget.pyqSet.questions.length - 1
                                ? 'Finish'
                                : 'Next')
                          : 'Check Answer',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index) {
    final isSelected = _selectedAnswer == index;
    final isCorrect = index == _currentQuestion.correctAnswer;
    final showResult = _showAnswer;

    Color? backgroundColor;
    Color? borderColor;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = Colors.green[50];
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red[50];
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      backgroundColor = Colors.blue[50];
      borderColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        border: Border.all(color: borderColor ?? Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: showResult
            ? null
            : () {
                setState(() {
                  _selectedAnswer = index;
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: showResult && isCorrect
                      ? Colors.green
                      : (showResult && isSelected && !isCorrect
                            ? Colors.red
                            : (isSelected ? Colors.blue : Colors.grey[300])),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: isSelected || (showResult && isCorrect)
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
                  _currentQuestion.options[index],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              if (showResult && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green),
              if (showResult && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_score / widget.pyqSet.totalMarks * 100)
        .toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Complete'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'Practice Complete!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        widget.pyqSet.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            'Score',
                            '$_score / ${widget.pyqSet.totalMarks}',
                            Colors.blue,
                          ),
                          _buildStatColumn(
                            'Percentage',
                            '$percentage%',
                            Colors.green,
                          ),
                          _buildStatColumn(
                            'Questions',
                            '${widget.pyqSet.questions.length}',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Back to PYQ Sets',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
