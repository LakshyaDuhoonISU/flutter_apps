// Class Schedule Screen
// Shows schedule of all classes from enrolled courses

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/course_service.dart';
import '../utils/video_status_helper.dart';

// Conditional imports for web
import 'dart:ui_web' as ui_web show platformViewRegistry;
import 'dart:html' show IFrameElement;

class ClassScheduleScreen extends StatefulWidget {
  const ClassScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ClassScheduleScreen> createState() => _ClassScheduleScreenState();
}

class _ClassScheduleScreenState extends State<ClassScheduleScreen> {
  late Future<List<dynamic>> _scheduleFuture;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = CourseService.getMySchedule();
    // Default to today so students see only today's schedule on open
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  // Filter classes by date
  List<dynamic> _filterClassesByDate(List<dynamic> classes) {
    if (_selectedDate == null) return classes;

    final selectedDateIST = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    return classes.where((cls) {
      if (cls['scheduledAt'] == null) return false;

      final scheduledAt = DateTime.parse(cls['scheduledAt']);
      final scheduledLocal =
          (scheduledAt.isUtc
                  ? scheduledAt
                  : DateTime.utc(
                      scheduledAt.year,
                      scheduledAt.month,
                      scheduledAt.day,
                      scheduledAt.hour,
                      scheduledAt.minute,
                      scheduledAt.second,
                    ))
              .toLocal();
      final scheduledDateLocal = DateTime(
        scheduledLocal.year,
        scheduledLocal.month,
        scheduledLocal.day,
      );

      return scheduledDateLocal.isAtSameMomentAs(selectedDateIST);
    }).toList();
  }

  // Select date
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Clear date filter (show all days)
  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  // Launch video URL and mark as completed
  Future<void> _launchVideo(String url, String classId, String title) async {
    try {
      // Mark class as completed first
      await CourseService.markClassCompleted(classId);

      // Refresh the schedule data to update completion status
      setState(() {
        _scheduleFuture = CourseService.getMySchedule();
      });

      // Show video player
      _showVideoDialog(url, title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Show video dialog
  void _showVideoDialog(String videoUrl, String title) {
    String? videoId = _extractYouTubeVideoId(videoUrl);

    if (videoId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invalid Video'),
          content: const Text(
            'This video URL is not supported. Please use a valid YouTube URL.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _VideoPlayerDialog(videoId: videoId, title: title),
    );
  }

  // Extract YouTube video ID from various URL formats
  String? _extractYouTubeVideoId(String url) {
    url = url.trim();

    RegExp regExp1 = RegExp(
      r'(?:youtube\.com\/watch\?v=)([\w-]+)',
      caseSensitive: false,
    );
    Match? match1 = regExp1.firstMatch(url);
    if (match1 != null && match1.groupCount >= 1) {
      return match1.group(1);
    }

    RegExp regExp2 = RegExp(r'(?:youtu\.be\/)([\w-]+)', caseSensitive: false);
    Match? match2 = regExp2.firstMatch(url);
    if (match2 != null && match2.groupCount >= 1) {
      return match2.group(1);
    }

    RegExp regExp3 = RegExp(
      r'(?:youtube\.com\/embed\/)([\w-]+)',
      caseSensitive: false,
    );
    Match? match3 = regExp3.firstMatch(url);
    if (match3 != null && match3.groupCount >= 1) {
      return match3.group(1);
    }

    if (url.length == 11 && RegExp(r'^[\w-]+$').hasMatch(url)) {
      return url;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Schedule'),
        centerTitle: true,
        actions: [
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearDateFilter,
              tooltip: 'Clear filter',
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            );
          }

          // Success state
          final allClasses = snapshot.data!;
          final filteredClasses = _filterClassesByDate(allClasses);

          if (allClasses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No classes scheduled',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enroll in courses to see classes',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          if (filteredClasses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _selectedDate != null
                        ? 'No classes on ${_formatDate(_selectedDate!)}'
                        : 'No classes scheduled',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedDate != null)
                    ElevatedButton.icon(
                      onPressed: _clearDateFilter,
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Show all days'),
                    ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Date filter info
              if (_selectedDate != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Showing classes for: ${_formatDate(_selectedDate!)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Class list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredClasses.length,
                  itemBuilder: (context, index) {
                    final cls = filteredClasses[index];
                    return _buildClassCard(cls);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build class card
  Widget _buildClassCard(Map<String, dynamic> cls) {
    final classId = cls['_id'] ?? '';
    final title = cls['title'] ?? 'Untitled';
    final videoUrl = cls['videoUrl'] ?? '';
    final courseName = cls['courseName'] ?? 'Unknown Course';
    final courseSubject = cls['courseSubject'] ?? '';
    final topicName = cls['topicName'] ?? 'Unknown Topic';
    final topicDescription = cls['topicDescription'] ?? '';
    final educatorName = cls['educatorName'] ?? 'Unknown Educator';
    final description = cls['description'] ?? '';
    final durationMinutes = cls['durationMinutes'] ?? 60;

    final scheduledAt = cls['scheduledAt'] != null
        ? DateTime.parse(cls['scheduledAt'])
        : null;

    final status = VideoStatusHelper.getVideoStatus(
      scheduledAt,
      durationMinutes,
    );
    final statusText = VideoStatusHelper.getStatusText(status);
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: videoUrl.isNotEmpty && status != VideoStatus.upcoming
            ? () => _launchVideo(videoUrl, classId, title)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge and title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Course info
              Row(
                children: [
                  const Icon(Icons.book, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$courseName${courseSubject.isNotEmpty ? ' ($courseSubject)' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Topic info
              Row(
                children: [
                  const Icon(Icons.topic, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      topicName,
                      style: const TextStyle(fontSize: 13, color: Colors.green),
                    ),
                  ),
                ],
              ),

              if (topicDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Text(
                    topicDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Educator info
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'By $educatorName',
                    style: const TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                ],
              ),

              if (scheduledAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      status == VideoStatus.live
                          ? Icons.live_tv
                          : status == VideoStatus.upcoming
                          ? Icons.schedule
                          : Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatDateTime(scheduledAt)} • $durationMinutes min',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],

              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],

              // Watch button
              if (videoUrl.isNotEmpty && status != VideoStatus.upcoming) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchVideo(videoUrl, classId, title),
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: Text(
                      status == VideoStatus.live ? 'Watch Live' : 'Watch Video',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(VideoStatus status) {
    switch (status) {
      case VideoStatus.live:
        return Colors.red;
      case VideoStatus.upcoming:
        return Colors.orange;
      case VideoStatus.recorded:
        return Colors.green;
    }
  }

  String _formatDateTime(DateTime dt) {
    // Parse as UTC if not already, then convert to local (IST) for display
    final local =
        (dt.isUtc
                ? dt
                : DateTime.utc(
                    dt.year,
                    dt.month,
                    dt.day,
                    dt.hour,
                    dt.minute,
                    dt.second,
                  ))
            .toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// Video Player Dialog Widget
class _VideoPlayerDialog extends StatefulWidget {
  final String videoId;
  final String title;

  const _VideoPlayerDialog({
    Key? key,
    required this.videoId,
    required this.title,
  }) : super(key: key);

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  String? _iframeViewType;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _registerIframe();
    }
  }

  void _registerIframe() {
    _iframeViewType = 'youtube-player-${widget.videoId}';
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_iframeViewType!, (
      int viewId,
    ) {
      final iframe = IFrameElement()
        ..src = 'https://www.youtube.com/embed/${widget.videoId}'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
        ..allowFullscreen = true;
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: kIsWeb
                  ? HtmlElementView(viewType: _iframeViewType!)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.video_library,
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Open in YouTube',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(
                                'https://www.youtube.com/watch?v=${widget.videoId}',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open YouTube'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
