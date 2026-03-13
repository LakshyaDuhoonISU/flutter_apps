// Enrolled Course Detail Screen
// Shows course content for enrolled students (only recorded/live videos)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/course_service.dart';
import '../services/socket_service.dart';
import '../models/course_model.dart';
import '../utils/video_status_helper.dart';
import '../utils/constants.dart';
import '../widgets/live_class_interaction_widget.dart';

// Conditional imports for web
import 'dart:ui_web' as ui_web show platformViewRegistry;
import 'dart:html' show IFrameElement;

class EnrolledCourseDetailScreen extends StatefulWidget {
  final String courseId;

  const EnrolledCourseDetailScreen({Key? key, required this.courseId})
    : super(key: key);

  @override
  State<EnrolledCourseDetailScreen> createState() =>
      _EnrolledCourseDetailScreenState();
}

class _EnrolledCourseDetailScreenState
    extends State<EnrolledCourseDetailScreen> {
  late Future<Map<String, dynamic>> _courseFuture;
  Set<String> _completedClassIds = {};
  Set<String> _bookmarkedClassIds = {};

  @override
  void initState() {
    super.initState();
    _courseFuture = CourseService.getCourseById(widget.courseId);
    _loadBookmarks();
  }

  // Refresh the entire screen
  void _refresh() {
    setState(() {
      _courseFuture = CourseService.getCourseById(widget.courseId);
    });
    _loadBookmarks();
  }

  // Load bookmarked classes
  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await CourseService.getBookmarkedClasses();
      if (mounted) {
        setState(() {
          _bookmarkedClassIds = bookmarks
              .map((cls) => cls['_id'].toString())
              .toSet();
        });
      }
    } catch (e) {
      // Silently fail - bookmarks are optional
    }
  }

  // Launch video URL and mark as completed
  Future<void> _launchVideo(
    String url,
    String classId,
    String title,
    DateTime? scheduledAt,
    int durationMinutes,
  ) async {
    try {
      // Mark class as completed first
      await CourseService.markClassCompleted(classId);

      // Update local state and reload data from server
      setState(() {
        _completedClassIds.add(classId);
        // Refresh the course data to update completion percentage
        _courseFuture = CourseService.getCourseById(widget.courseId);
      });

      // Calculate video status
      final status = VideoStatusHelper.getVideoStatus(
        scheduledAt,
        durationMinutes,
      );

      // Show video player
      _showVideoDialog(url, title, classId, status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Toggle bookmark for a class
  Future<void> _toggleBookmark(String classId) async {
    try {
      final isBookmarked = _bookmarkedClassIds.contains(classId);

      if (isBookmarked) {
        // Remove bookmark
        await CourseService.unbookmarkClass(classId);
        setState(() {
          _bookmarkedClassIds.remove(classId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bookmark removed'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Add bookmark
        await CourseService.bookmarkClass(classId);
        setState(() {
          _bookmarkedClassIds.add(classId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video bookmarked'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Show video dialog
  void _showVideoDialog(
    String videoUrl,
    String title,
    String classId,
    VideoStatus status,
  ) {
    // Extract video ID from YouTube URL
    String? videoId = _extractYouTubeVideoId(videoUrl);

    if (videoId == null) {
      // If not a valid YouTube URL, show error
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

    // Show video player dialog
    showDialog(
      context: context,
      builder: (context) => _VideoPlayerDialog(
        videoId: videoId,
        title: title,
        classId: classId,
        isLive: status == VideoStatus.live,
      ),
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
        title: const Text('Course Content'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _courseFuture,
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
          final courseData = snapshot.data!;
          final course = Course.fromJson(courseData['course']);
          final topics = courseData['topics'] as List? ?? [];
          final classes = courseData['classes'] as List? ?? [];
          final completedClassIds =
              (courseData['completedClassIds'] as List?)?.cast<String>() ?? [];

          // Always update completed class IDs from server data
          _completedClassIds = Set<String>.from(completedClassIds);

          // Group ALL classes by topicId (including upcoming)
          final Map<String, List<dynamic>> topicClasses = {};
          for (var cls in classes) {
            final topicId = cls['topicId'] is Map
                ? cls['topicId']['_id']
                : cls['topicId'];
            if (!topicClasses.containsKey(topicId)) {
              topicClasses[topicId] = [];
            }
            topicClasses[topicId]!.add(cls);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Course header
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Subject: ${course.subject}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (course.educatorName != null)
                        Text(
                          'Educator: ${course.educatorName}',
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Topics and Classes Section
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (topics.isEmpty) ...[
                        const Center(
                          child: Text(
                            'No content available yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Course Content',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...topics.map((topic) {
                          final topicId = topic['_id'];
                          final topicTitle = topic['title'] ?? '';
                          final topicDesc = topic['description'] ?? '';
                          final classList = topicClasses[topicId] ?? [];

                          // Count only watchable (live/recorded) for completion %
                          final watchableList = classList.where((cls) {
                            final scheduledAt = cls['scheduledAt'] != null
                                ? DateTime.parse(cls['scheduledAt'])
                                : null;
                            final dur = cls['durationMinutes'] ?? 60;
                            final st = VideoStatusHelper.getVideoStatus(
                              scheduledAt,
                              dur,
                            );
                            return st != VideoStatus.upcoming;
                          }).toList();

                          // Calculate completion percentage
                          final completedCount = watchableList.where((cls) {
                            final classId = cls['_id'];
                            return _completedClassIds.contains(classId);
                          }).length;
                          final totalCount = watchableList.length;
                          final completionPercent = totalCount > 0
                              ? (completedCount / totalCount * 100).round()
                              : 0;

                          return _buildTopicSection(
                            topicTitle,
                            topicDesc,
                            classList,
                            completionPercent,
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build topic section with classes
  Widget _buildTopicSection(
    String title,
    String description,
    List<dynamic> classes,
    int completionPercent,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: completionPercent == 100
                    ? Colors.green[50]
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: completionPercent == 100 ? Colors.green : Colors.blue,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    completionPercent == 100
                        ? Icons.check_circle
                        : Icons.pie_chart,
                    size: 14,
                    color: completionPercent == 100
                        ? Colors.green
                        : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$completionPercent%',
                    style: TextStyle(
                      color: completionPercent == 100
                          ? Colors.green
                          : Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        children: [...classes.map((cls) => _buildClassTile(cls)).toList()],
      ),
    );
  }

  // Build individual class tile with status badge
  Widget _buildClassTile(Map<String, dynamic> cls) {
    final classId = cls['_id'] ?? '';
    final title = cls['title'] ?? '';
    final videoUrl = cls['videoUrl'] ?? '';
    final scheduledAt = cls['scheduledAt'] != null
        ? DateTime.parse(cls['scheduledAt'])
        : null;
    final durationMinutes = cls['durationMinutes'] ?? 60;
    final isCompleted = _completedClassIds.contains(classId);

    final status = VideoStatusHelper.getVideoStatus(
      scheduledAt,
      durationMinutes,
    );
    final statusText = VideoStatusHelper.getStatusText(status);
    final statusColor = _getStatusColor(status);

    // Upcoming classes: show as non-interactive locked tile
    if (status == VideoStatus.upcoming) {
      return ListTile(
        leading: Icon(Icons.lock_clock, color: statusColor),
        title: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.black54)),
            ),
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
        subtitle: scheduledAt != null
            ? Text(
                'Scheduled: ${_formatDateTime(scheduledAt)}',
                style: const TextStyle(fontSize: 12),
              )
            : null,
      );
    }

    return ListTile(
      leading: Icon(
        isCompleted
            ? Icons.check_circle
            : (status == VideoStatus.live
                  ? Icons.live_tv
                  : Icons.play_circle_filled),
        color: isCompleted ? Colors.green : statusColor,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : null,
              ),
            ),
          ),
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scheduledAt != null)
            Text(
              'Scheduled: ${_formatDateTime(scheduledAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          if (isCompleted)
            Row(
              children: [
                Icon(Icons.done, size: 12, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: videoUrl.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show bookmark button only for recorded videos
                if (status == VideoStatus.recorded)
                  IconButton(
                    icon: Icon(
                      _bookmarkedClassIds.contains(classId)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: _bookmarkedClassIds.contains(classId)
                          ? Colors.amber
                          : Colors.grey,
                    ),
                    onPressed: () => _toggleBookmark(classId),
                    tooltip: _bookmarkedClassIds.contains(classId)
                        ? 'Remove bookmark'
                        : 'Bookmark video',
                  ),
                IconButton(
                  icon: Icon(
                    isCompleted ? Icons.replay : Icons.play_arrow,
                    color: Colors.green,
                  ),
                  onPressed: () => _launchVideo(
                    videoUrl,
                    classId,
                    title,
                    scheduledAt,
                    durationMinutes,
                  ),
                  tooltip: isCompleted ? 'Rewatch Video' : 'Watch Video',
                ),
              ],
            )
          : null,
      onTap: videoUrl.isNotEmpty
          ? () => _launchVideo(
              videoUrl,
              classId,
              title,
              scheduledAt,
              durationMinutes,
            )
          : null,
    );
  }

  Color _getStatusColor(VideoStatus status) {
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

// Video Player Dialog Widget
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
  String? _userRole;
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

    // Load user data
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString(userRoleKey) ?? 'student';
    final userId = prefs.getString(userIdKey) ?? '';

    if (!mounted) return;

    setState(() {
      _userRole = userRole;
      _userId = userId;
      _isLoadingUserData = false;
    });

    // Initialize socket only for live classes
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
  void dispose() {
    // Don't dispose socket here as it might be used by other widgets
    super.dispose();
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
            // Add live interaction widget only for live classes
            if (widget.isLive &&
                !_isLoadingUserData &&
                _userRole != null &&
                _userId != null)
              LiveClassInteractionWidget(
                classId: widget.classId,
                userRole: _userRole!,
                userId: _userId!,
                onClassEnded: _handleClassEnded,
              ),
          ],
        ),
      ),
    );
  }
}
