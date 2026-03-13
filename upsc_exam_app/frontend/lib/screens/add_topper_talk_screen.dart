// Add/Edit Topper Talk Screen
// Form to create or update topper talk videos

import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';

class AddTopperTalkScreen extends StatefulWidget {
  final String? talkId;
  final Map<String, dynamic>? talkData;

  const AddTopperTalkScreen({Key? key, this.talkId, this.talkData})
    : super(key: key);

  @override
  State<AddTopperTalkScreen> createState() => _AddTopperTalkScreenState();
}

class _AddTopperTalkScreenState extends State<AddTopperTalkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _topperNameController = TextEditingController();
  final _rankController = TextEditingController();
  final _yearController = TextEditingController();
  final _optionalController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.talkData != null) {
      _populateFormWithExistingData();
    }
  }

  // Populate form with existing data for editing
  void _populateFormWithExistingData() {
    final data = widget.talkData!;
    _titleController.text = data['title'] ?? '';
    _topperNameController.text = data['topperName'] ?? '';
    _rankController.text = (data['rank'] ?? '').toString();
    _yearController.text = (data['year'] ?? '').toString();
    _optionalController.text = data['optional'] ?? '';
    _videoUrlController.text = data['videoUrl'] ?? '';
    _thumbnailController.text = data['thumbnail'] ?? '';
    _durationController.text = (data['durationMinutes'] ?? '').toString();
    _descriptionController.text = data['description'] ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topperNameController.dispose();
    _rankController.dispose();
    _yearController.dispose();
    _optionalController.dispose();
    _videoUrlController.dispose();
    _thumbnailController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Submit form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final body = {
        'title': _titleController.text.trim(),
        'topperName': _topperNameController.text.trim(),
        'rank': int.parse(_rankController.text.trim()),
        'year': int.parse(_yearController.text.trim()),
        'optional': _optionalController.text.trim(),
        'videoUrl': _videoUrlController.text.trim(),
        'thumbnail': _thumbnailController.text.trim(),
        'durationMinutes': _durationController.text.trim().isEmpty
            ? 0
            : int.parse(_durationController.text.trim()),
        'description': _descriptionController.text.trim(),
      };

      final response = widget.talkId == null
          ? await ApiService.post('/topper-talks', body)
          : await ApiService.put('/topper-talks/${widget.talkId}', body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
        Navigator.of(context).pop(true);
      } else {
        throw Exception(data['message'] ?? 'Failed to save topper talk');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.talkId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Topper Talk' : 'Add Topper Talk'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                  hintText: 'e.g., Journey to AIR 1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // Topper name
              TextFormField(
                controller: _topperNameController,
                decoration: const InputDecoration(
                  labelText: 'Topper Name *',
                  hintText: 'e.g., Tina Dabi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter topper name';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // Rank and Year
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rankController,
                      decoration: const InputDecoration(
                        labelText: 'Rank *',
                        hintText: '1',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.emoji_events),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter rank';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                      enabled: !_isSubmitting,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year *',
                        hintText: '2024',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter year';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                      enabled: !_isSubmitting,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Optional subject
              TextFormField(
                controller: _optionalController,
                decoration: const InputDecoration(
                  labelText: 'Optional Subject',
                  hintText: 'e.g., Sociology',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // Video URL
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL *',
                  hintText: 'https://www.youtube.com/watch?v=...',
                  helperText: 'YouTube video link (will play in-app)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter video URL';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Thumbnail URL
              TextFormField(
                controller: _thumbnailController,
                decoration: const InputDecoration(
                  labelText: 'Thumbnail URL (Optional)',
                  hintText: 'Image link for thumbnail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                ),
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // Duration
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  hintText: 'e.g., 45',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.number,
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of the session',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Topper Talk' : 'Add Topper Talk',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),

              const SizedBox(height: 16),

              // Info card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Note',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• All topper talks are free and accessible to all students\n'
                        '• Use YouTube URLs (videos will play in-app)\n'
                        '• Supported formats: youtube.com/watch, youtu.be, youtube.com/embed\n'
                        '• Add detailed descriptions to help students',
                        style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
