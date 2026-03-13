// Course Detail Screen
// Shows details of a specific course and allows navigation to tests

import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import '../utils/video_status_helper.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({Key? key, required this.courseId})
    : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Future<Map<String, dynamic>> _courseFuture;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _courseFuture = CourseService.getCourseById(widget.courseId);
  }

  // Handle enrollment
  Future<void> _handleEnroll() async {
    setState(() {
      _isEnrolling = true;
    });

    try {
      await CourseService.enrollInCourse(widget.courseId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully enrolled in course!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Clean up error message by removing "Exception: " prefix if present
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isEnrolling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Details'), centerTitle: true),
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
          final isEnrolled = courseData['isEnrolled'] ?? false;

          // Group classes by topicId
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

                // Course info
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),

                      // Course details
                      _buildDetailRow(
                        Icons.people,
                        'Enrolled Students',
                        '${course.enrolledStudents}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.currency_rupee,
                        'Price',
                        '₹${course.price.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.workspace_premium,
                        'Plus Included',
                        course.isPlusIncluded ? 'Yes' : 'No',
                      ),
                      const SizedBox(height: 30),

                      // Enroll button (only show if not enrolled)
                      if (!isEnrolled)
                        ElevatedButton(
                          onPressed: _isEnrolling ? null : _handleEnroll,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isEnrolling
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Enroll in Course',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),

                      // Already enrolled message
                      if (isEnrolled)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You are enrolled in this course',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 30),

                      // Topics and Classes Section
                      if (topics.isNotEmpty) ...[
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
                          return _buildTopicSection(
                            topicTitle,
                            topicDesc,
                            classList,
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
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        children: [
          if (classes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No classes available yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...classes.map((cls) => _buildClassTile(cls)).toList(),
        ],
      ),
    );
  }

  // Build individual class tile with status badge
  Widget _buildClassTile(Map<String, dynamic> cls) {
    final title = cls['title'] ?? '';
    final scheduledAt = cls['scheduledAt'] != null
        ? DateTime.parse(cls['scheduledAt'])
        : null;
    final durationMinutes = cls['durationMinutes'] ?? 60;

    final status = VideoStatusHelper.getVideoStatus(
      scheduledAt,
      durationMinutes,
    );
    final statusText = VideoStatusHelper.getStatusText(status);
    final statusColor = _getStatusColor(status);

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
          Expanded(child: Text(title)),
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

  // Helper widget for detail rows
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
