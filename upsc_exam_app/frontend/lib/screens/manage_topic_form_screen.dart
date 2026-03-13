// Manage Topic Form Screen
// Form to create or edit a topic

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ManageTopicFormScreen extends StatefulWidget {
  final String courseId;
  final String? topicId;
  final Map<String, dynamic>? topicData;

  const ManageTopicFormScreen({
    Key? key,
    required this.courseId,
    this.topicId,
    this.topicData,
  }) : super(key: key);

  @override
  State<ManageTopicFormScreen> createState() => _ManageTopicFormScreenState();
}

class _ManageTopicFormScreenState extends State<ManageTopicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderIndexController = TextEditingController();
  final _estimatedHoursController = TextEditingController();
  bool _isLoading = false;
  List<int> _existingPositions = [];
  bool _isFetchingTopics = true;

  bool get _isEditMode => widget.topicId != null;

  @override
  void initState() {
    super.initState();
    _fetchExistingTopics();
    if (_isEditMode && widget.topicData != null) {
      _titleController.text = widget.topicData!['title'] ?? '';
      _descriptionController.text = widget.topicData!['description'] ?? '';
      // Display orderIndex + 1 to users (1-based instead of 0-based)
      final orderIndex = widget.topicData!['orderIndex'] ?? 0;
      _orderIndexController.text = (orderIndex + 1).toString();
      _estimatedHoursController.text =
          widget.topicData!['estimatedHours']?.toString() ?? '0';
    } else {
      // Default to position 1 for new topics
      _orderIndexController.text = '1';
    }
  }

  Future<void> _fetchExistingTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);

      final response = await http.get(
        Uri.parse('$baseUrl/courses/${widget.courseId}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final topics = data['data']['topics'] as List;

        setState(() {
          // Store existing positions (in 1-based format) excluding current topic if editing
          _existingPositions = topics
              .where(
                (topic) => _isEditMode ? topic['_id'] != widget.topicId : true,
              )
              .map<int>((topic) => (topic['orderIndex'] as int) + 1)
              .toList();
          _isFetchingTopics = false;
        });
      } else {
        setState(() {
          _isFetchingTopics = false;
        });
      }
    } catch (e) {
      setState(() {
        _isFetchingTopics = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _orderIndexController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }

  Future<void> _saveTopic() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);

      final body = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        // Convert from 1-based (user input) to 0-based (backend storage)
        'orderIndex': int.parse(_orderIndexController.text.trim()) - 1,
        'estimatedHours': int.parse(_estimatedHoursController.text.trim()),
      };

      final url = _isEditMode
          ? '$baseUrl/courses/${widget.courseId}/topics/${widget.topicId}'
          : '$baseUrl/courses/${widget.courseId}/topics';

      final response = _isEditMode
          ? await http.put(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(body),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(body),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? 'Topic updated successfully'
                    : 'Topic created successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final error = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['message'] ?? 'Failed to save topic'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
        title: Text(_isEditMode ? 'Edit Topic' : 'Create Topic'),
        centerTitle: true,
      ),
      body: _isFetchingTopics
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Topic Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter topic title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _orderIndexController,
                    decoration: const InputDecoration(
                      labelText: 'Topic Position',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.format_list_numbered),
                      helperText: 'Order in which topic appears (1, 2, 3, ...)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter topic position';
                      }
                      final num = int.tryParse(value);
                      if (num == null || num < 1) {
                        return 'Please enter valid position (minimum 1)';
                      }
                      // Check if position is already taken by another topic
                      if (_existingPositions.contains(num)) {
                        return 'Position $num is already taken by another topic';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _estimatedHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Hours',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter estimated hours';
                      }
                      final hours = int.tryParse(value);
                      if (hours == null) {
                        return 'Please enter valid number';
                      }
                      if (hours < 0) {
                        return 'Estimated hours cannot be negative';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTopic,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(_isEditMode ? 'Update Topic' : 'Create Topic'),
                  ),
                ],
              ),
            ),
    );
  }
}
