// Topper Talks Screen
// Displays videos from UPSC toppers

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'add_topper_talk_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditional imports for web
import 'dart:ui_web' as ui_web show platformViewRegistry;
import 'dart:html' show IFrameElement;

class TopperTalksScreen extends StatefulWidget {
  const TopperTalksScreen({Key? key}) : super(key: key);

  @override
  State<TopperTalksScreen> createState() => _TopperTalksScreenState();
}

class _TopperTalksScreenState extends State<TopperTalksScreen> {
  late Future<List<dynamic>> _talksFuture;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _talksFuture = _fetchTopperTalks();
    _loadUserRole();
  }

  // Load user role
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString(userRoleKey) ?? 'student';
    });
  }

  // Fetch topper talks
  Future<List<dynamic>> _fetchTopperTalks() async {
    try {
      final response = await ApiService.get('/topper-talks');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'] as List;
      } else {
        throw Exception(data['message'] ?? 'Failed to load topper talks');
      }
    } catch (e) {
      throw Exception('Error loading topper talks: $e');
    }
  }

  // Refresh talks
  Future<void> _refreshTalks() async {
    setState(() {
      _talksFuture = _fetchTopperTalks();
    });
  }

  // Delete topper talk
  Future<void> _deleteTopperTalk(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topper Talk'),
        content: const Text('Are you sure you want to delete this video?'),
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

    if (confirm != true) return;

    try {
      final response = await ApiService.delete('/topper-talks/$id');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
        _refreshTalks();
      } else {
        throw Exception(data['message'] ?? 'Failed to delete');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Topper Talks'), centerTitle: true),
      floatingActionButton: _userRole == 'educator'
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddTopperTalkScreen(),
                  ),
                );
                if (result == true) {
                  _refreshTalks();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refreshTalks,
        child: FutureBuilder<List<dynamic>>(
          future: _talksFuture,
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
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshTalks,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Success state
            final talks = snapshot.data!;

            // No talks
            if (talks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No topper talks available',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // Display talks
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: talks.length,
              itemBuilder: (context, index) {
                final talk = talks[index];
                return _buildTalkCard(talk);
              },
            );
          },
        ),
      ),
    );
  }

  // Build talk card
  Widget _buildTalkCard(Map<String, dynamic> talk) {
    final id = talk['_id'] ?? '';
    final title = talk['title'] ?? 'No Title';
    final topperName = talk['topperName'] ?? 'Unknown';
    final rank = talk['rank'] ?? 0;
    final year = talk['year'] ?? 0;
    final optional = talk['optional'] ?? '';
    final description = talk['description'] ?? '';
    final durationMinutes = talk['durationMinutes'] ?? 0;
    final videoUrl = talk['videoUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail/header
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_fill,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rank $rank - AIR $year',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Topper name
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      topperName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                if (optional.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.subject, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Optional: $optional',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],

                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    if (durationMinutes > 0) ...[
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$durationMinutes min',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    const Spacer(),
                    // Watch button
                    ElevatedButton.icon(
                      onPressed: () {
                        _showVideoDialog(videoUrl, title);
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Watch'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),

                // Educator actions
                if (_userRole == 'educator') ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddTopperTalkScreen(
                                talkId: id,
                                talkData: talk,
                              ),
                            ),
                          );
                          if (result == true) {
                            _refreshTalks();
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _deleteTopperTalk(id),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show video dialog
  void _showVideoDialog(String videoUrl, String title) {
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
      builder: (context) => VideoPlayerDialog(videoId: videoId, title: title),
    );
  }

  // Extract YouTube video ID from various URL formats
  String? _extractYouTubeVideoId(String url) {
    // Remove whitespace
    url = url.trim();

    // Pattern 1: https://www.youtube.com/watch?v=VIDEO_ID
    RegExp regExp1 = RegExp(
      r'(?:youtube\.com\/watch\?v=)([\w-]+)',
      caseSensitive: false,
    );
    Match? match1 = regExp1.firstMatch(url);
    if (match1 != null && match1.groupCount >= 1) {
      return match1.group(1);
    }

    // Pattern 2: https://youtu.be/VIDEO_ID
    RegExp regExp2 = RegExp(r'(?:youtu\.be\/)([\w-]+)', caseSensitive: false);
    Match? match2 = regExp2.firstMatch(url);
    if (match2 != null && match2.groupCount >= 1) {
      return match2.group(1);
    }

    // Pattern 3: https://www.youtube.com/embed/VIDEO_ID
    RegExp regExp3 = RegExp(
      r'(?:youtube\.com\/embed\/)([\w-]+)',
      caseSensitive: false,
    );
    Match? match3 = regExp3.firstMatch(url);
    if (match3 != null && match3.groupCount >= 1) {
      return match3.group(1);
    }

    // If URL is just the video ID
    if (url.length == 11 && RegExp(r'^[\w-]+$').hasMatch(url)) {
      return url;
    }

    return null;
  }
}

// Video Player Dialog Widget
class VideoPlayerDialog extends StatefulWidget {
  final String videoId;
  final String title;

  const VideoPlayerDialog({
    Key? key,
    required this.videoId,
    required this.title,
  }) : super(key: key);

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  String? _iframeViewType;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _registerIframe();
    }
  }

  void _registerIframe() {
    // Create unique view type for this iframe
    _iframeViewType = 'youtube-player-${widget.videoId}';

    // Register the iframe view factory
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
            // Header with title and close button
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
            // Video player
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
