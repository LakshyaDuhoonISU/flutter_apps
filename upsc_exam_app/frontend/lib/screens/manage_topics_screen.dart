// Manage Topics Screen
// Shows all topics in a course and allows managing them and their classes

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../utils/video_status_helper.dart';
import '../services/socket_service.dart';
import '../widgets/live_class_interaction_widget.dart';
import 'manage_topic_form_screen.dart';
import 'manage_class_form_screen.dart';

// Conditional imports for web
import 'dart:ui_web' as ui_web show platformViewRegistry;
import 'dart:html' show IFrameElement;

class ManageTopicsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const ManageTopicsScreen({
    Key? key,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  State<ManageTopicsScreen> createState() => _ManageTopicsScreenState();
}

class _ManageTopicsScreenState extends State<ManageTopicsScreen> {
  List<dynamic> _topics = [];
  Map<String, List<dynamic>> _topicClasses = {};
  bool _isLoading = true;
  String? _error;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _fetchCourseData();
    // Refresh status badges every 30 s so upcoming→live→recorded transitions
    // are reflected without needing to navigate away.
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCourseData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
        final classes = data['data']['classes'] as List;

        // Group classes by topicId
        final Map<String, List<dynamic>> grouped = {};
        for (var cls in classes) {
          final topicId = cls['topicId']['_id'] ?? cls['topicId'];
          if (!grouped.containsKey(topicId)) {
            grouped[topicId] = [];
          }
          grouped[topicId]!.add(cls);
        }

        setState(() {
          _topics = topics;
          _topicClasses = grouped;
          _isLoading = false;
        });
      } else {
        final error = json.decode(response.body);
        setState(() {
          _error = error['message'] ?? 'Failed to fetch course data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTopic(String topicId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: const Text(
          'Are you sure you want to delete this topic? This will also delete all classes in this topic.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);

      final response = await http.delete(
        Uri.parse('$baseUrl/courses/${widget.courseId}/topics/$topicId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Topic deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchCourseData();
        }
      } else {
        final error = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['message'] ?? 'Failed to delete topic'),
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
    }
  }

  Future<void> _deleteClass(String classId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('Are you sure you want to delete this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);

      final response = await http.delete(
        Uri.parse('$baseUrl/courses/${widget.courseId}/classes/$classId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Class deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchCourseData();
        }
      } else {
        final error = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['message'] ?? 'Failed to delete class'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchCourseData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ManageTopicFormScreen(courseId: widget.courseId),
            ),
          );
          if (result == true) {
            _fetchCourseData();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchCourseData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _topics.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.topic, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No topics added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add your first topic',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchCourseData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _topics.length,
                itemBuilder: (context, index) {
                  final topic = _topics[index];
                  final topicId = topic['_id'];
                  final classes = _topicClasses[topicId] ?? [];
                  return _buildTopicCard(topic, classes);
                },
              ),
            ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic, List<dynamic> classes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                topic['title'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Topic'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_class',
                  child: Row(
                    children: [
                      Icon(Icons.video_library, size: 20),
                      SizedBox(width: 8),
                      Text('Add Class'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Topic', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageTopicFormScreen(
                        courseId: widget.courseId,
                        topicId: topic['_id'],
                        topicData: topic,
                      ),
                    ),
                  );
                  if (result == true) _fetchCourseData();
                } else if (value == 'add_class') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageClassFormScreen(
                        courseId: widget.courseId,
                        topicId: topic['_id'],
                      ),
                    ),
                  );
                  if (result == true) _fetchCourseData();
                } else if (value == 'delete') {
                  _deleteTopic(topic['_id']);
                }
              },
            ),
          ],
        ),
        subtitle: Text(
          topic['description'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          if (classes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No classes added yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...classes
                .map((cls) => _buildClassTile(cls, topic['_id']))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildClassTile(Map<String, dynamic> cls, String topicId) {
    final scheduledAt = cls['scheduledAt'] != null
        ? DateTime.parse(cls['scheduledAt'])
        : null;
    final durationMinutes = cls['durationMinutes'] ?? 60;

    final status = VideoStatusHelper.getVideoStatus(
      scheduledAt,
      durationMinutes,
    );
    final statusText = VideoStatusHelper.getStatusText(status);
    final statusColor = _getStatusColorCode(status);

    return ListTile(
      leading: Icon(
        status == VideoStatus.live
            ? Icons.live_tv
            : status == VideoStatus.upcoming
            ? Icons.schedule
            : Icons.play_circle_filled,
        color: statusColor,
      ),
      title: Row(
        children: [
          Expanded(child: Text(cls['title'] ?? '')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      subtitle: Text(
        scheduledAt != null
            ? 'Scheduled: ${_formatDateTime(scheduledAt)}'
            : 'No schedule',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play button if video URL exists
          if (cls['videoUrl'] != null && cls['videoUrl'].toString().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              color: Colors.deepPurple,
              onPressed: () => _showVideoDialog(
                cls['videoUrl'],
                cls['title'] ?? '',
                cls['_id'],
                status,
              ),
              tooltip: 'Watch Video',
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageClassFormScreen(
                      courseId: widget.courseId,
                      topicId: topicId,
                      classId: cls['_id'],
                      classData: cls,
                    ),
                  ),
                );
                if (result == true) _fetchCourseData();
              } else if (value == 'delete') {
                _deleteClass(cls['_id']);
              }
            },
          ),
        ],
      ),
    );
  }

  // Show video dialog
  Future<void> _showVideoDialog(
    String videoUrl,
    String title,
    String classId,
    VideoStatus status,
  ) async {
    // Extract video ID from YouTube URL
    String? videoId = _extractYouTubeVideoId(videoUrl);

    if (videoId == null) {
      // If not a valid YouTube URL, show error
      await showDialog(
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

    // Show video player dialog
    await showDialog(
      context: context,
      builder: (context) => _VideoPlayerDialog(
        videoId: videoId,
        title: title,
        classId: classId,
        isLive: status == VideoStatus.live,
      ),
    );
    // Re-evaluate status badges immediately after the dialog closes
    if (mounted) setState(() {});
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

    return null;
  }

  Color _getStatusColorCode(VideoStatus status) {
    switch (status) {
      case VideoStatus.live:
        return Colors.red;
      case VideoStatus.upcoming:
        return Colors.orange;
      case VideoStatus.recorded:
        return Colors.grey;
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
}

// Video Player Dialog Widget (for educators)
class _VideoPlayerDialog extends StatefulWidget {
  final String videoId;
  final String title;
  final String classId;
  final bool isLive;

  const _VideoPlayerDialog({
    Key? key,
    required this.videoId,
    required this.title,
    required this.classId,
    required this.isLive,
  }) : super(key: key);

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  String? _iframeViewType;
  String? _userId;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _initializeDialog();
  }

  Future<void> _initializeDialog() async {
    if (kIsWeb) {
      _registerIframe();
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(userIdKey) ?? '';

    if (!mounted) return;

    setState(() {
      _userId = userId;
      _isLoadingUserData = false;
    });

    if (widget.isLive) {
      try {
        await SocketService.initialize(socketBaseUrl);
      } catch (e) {
        print('Socket initialization error: $e');
      }
    }
  }

  /// Called by LiveClassInteractionWidget when the class ends.
  void _handleClassEnded() {
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This class has ended and is now recorded.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _registerIframe() {
    _iframeViewType = 'youtube-player-educator-${widget.videoId}';
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
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header bar
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (widget.isLive)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
            // Video player
            Flexible(
              child: kIsWeb && _iframeViewType != null
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
                          ),
                        ],
                      ),
                    ),
            ),
            // Live interaction panel (educator view) - only for live classes
            if (widget.isLive && !_isLoadingUserData && _userId != null)
              LiveClassInteractionWidget(
                classId: widget.classId,
                userRole: 'educator',
                userId: _userId!,
                onClassEnded: _handleClassEnded,
              ),
          ],
        ),
      ),
    );
  }
}
