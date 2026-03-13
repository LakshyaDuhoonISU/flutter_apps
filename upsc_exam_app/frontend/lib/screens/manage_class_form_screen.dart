// Manage Class Form Screen
// Form to create or edit a class/video

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ManageClassFormScreen extends StatefulWidget {
  final String courseId;
  final String topicId;
  final String? classId;
  final Map<String, dynamic>? classData;

  const ManageClassFormScreen({
    Key? key,
    required this.courseId,
    required this.topicId,
    this.classId,
    this.classData,
  }) : super(key: key);

  @override
  State<ManageClassFormScreen> createState() => _ManageClassFormScreenState();
}

class _ManageClassFormScreenState extends State<ManageClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _durationMinutesController = TextEditingController();
  DateTime? _scheduledAt;
  bool _isLoading = false;

  bool get _isEditMode => widget.classId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode && widget.classData != null) {
      _titleController.text = widget.classData!['title'] ?? '';
      _descriptionController.text = widget.classData!['description'] ?? '';
      _videoUrlController.text = widget.classData!['videoUrl'] ?? '';
      _durationMinutesController.text =
          widget.classData!['durationMinutes']?.toString() ?? '60';
      if (widget.classData!['scheduledAt'] != null) {
        // Server stores UTC — parse and convert to local time for the picker
        _scheduledAt = DateTime.parse(
          widget.classData!['scheduledAt'],
        ).toLocal();
      }
    } else {
      _durationMinutesController.text = '60';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _durationMinutesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );

    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);

      // Convert local picker time to UTC before sending to server
      String? scheduledAtUTC;
      if (_scheduledAt != null) {
        scheduledAtUTC = _scheduledAt!.toUtc().toIso8601String();
      }

      final body = {
        'title': _titleController.text.trim(),
        'type': 'recorded',
        'description': _descriptionController.text.trim(),
        'videoUrl': _videoUrlController.text.trim(),
        'durationMinutes': int.parse(_durationMinutesController.text.trim()),
        if (scheduledAtUTC != null) 'scheduledAt': scheduledAtUTC,
      };

      final url = _isEditMode
          ? '$baseUrl/courses/${widget.courseId}/classes/${widget.classId}'
          : '$baseUrl/courses/${widget.courseId}/topics/${widget.topicId}/classes';

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
                    ? 'Class updated successfully'
                    : 'Class created successfully',
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
              content: Text(error['message'] ?? 'Failed to save class'),
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
        title: Text(_isEditMode ? 'Edit Class' : 'Create Class'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Class Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter class title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(
                labelText: 'Video URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                helperText: 'YouTube or other video platform URL',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Scheduled Date & Time (IST)'),
              subtitle: Text(
                _scheduledAt != null
                    ? '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} ${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                    : 'Not scheduled',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scheduledAt != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _scheduledAt = null;
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDateTime,
                  ),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            TextFormField(
              controller: _durationMinutesController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter duration';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter valid number';
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
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveClass,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_isEditMode ? 'Update Class' : 'Create Class'),
            ),
          ],
        ),
      ),
    );
  }
}
