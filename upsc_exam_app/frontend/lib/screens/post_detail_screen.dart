// Post Detail Screen
// Displays full post with replies and allows interaction

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../utils/constants.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String postTitle;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    required this.postTitle,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<Map<String, dynamic>> _postFuture;
  final TextEditingController _replyController = TextEditingController();
  String _userRole = 'student';
  String _userId = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _postFuture = _fetchPost();
    _loadUserData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  // Load user data
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString(userRoleKey) ?? 'student';
      _userId = prefs.getString(userIdKey) ?? '';
    });
  }

  // Fetch post details
  Future<Map<String, dynamic>> _fetchPost() async {
    try {
      final response = await ApiService.get('/community/${widget.postId}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to load post');
      }
    } catch (e) {
      throw Exception('Error loading post: $e');
    }
  }

  // Refresh post
  Future<void> _refreshPost() async {
    setState(() {
      _postFuture = _fetchPost();
    });
  }

  // Add reply
  Future<void> _addReply() async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a reply')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ApiService.post(
        '/community/reply/${widget.postId}',
        {'message': _replyController.text.trim()},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _replyController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply added successfully')),
        );
        _refreshPost();
      } else {
        throw Exception(data['message'] ?? 'Failed to add reply');
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

  // Upvote post
  Future<void> _upvotePost() async {
    try {
      final response = await ApiService.post(
        '/community/upvote/${widget.postId}',
        {},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
        _refreshPost();
      } else {
        throw Exception(data['message'] ?? 'Failed to upvote');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Lock/unlock post (educator only)
  Future<void> _toggleLock() async {
    try {
      final response = await ApiService.put(
        '/community/lock/${widget.postId}',
        {},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
        _refreshPost();
      } else {
        throw Exception(data['message'] ?? 'Failed to lock post');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Delete post (educator or owner)
  Future<void> _deletePost() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
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
      final response = await ApiService.delete('/community/${widget.postId}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
        Navigator.of(context).pop(true); // Return to previous screen
      } else {
        throw Exception(data['message'] ?? 'Failed to delete post');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Pin/unpin post (educator only)
  Future<void> _togglePin() async {
    try {
      final response = await ApiService.put(
        '/community/pin/${widget.postId}',
        {},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
        _refreshPost();
      } else {
        throw Exception(data['message'] ?? 'Failed to pin post');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Delete reply (educator or reply owner)
  Future<void> _deleteReply(String replyId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
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
      final response = await ApiService.delete(
        '/community/reply/${widget.postId}/$replyId',
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
        _refreshPost();
      } else {
        throw Exception(data['message'] ?? 'Failed to delete reply');
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
      appBar: AppBar(
        title: Text(widget.postTitle, overflow: TextOverflow.ellipsis),
        actions: [
          // Educator actions menu
          if (_userRole == 'educator')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'lock') {
                  _toggleLock();
                } else if (value == 'pin') {
                  _togglePin();
                } else if (value == 'delete') {
                  _deletePost();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'lock',
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 20),
                      SizedBox(width: 8),
                      Text('Lock/Unlock'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(Icons.push_pin, size: 20),
                      SizedBox(width: 8),
                      Text('Pin/Unpin'),
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
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _postFuture,
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshPost,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Success state
          final post = snapshot.data!;
          final title = post['title'] ?? 'No Title';
          final content = post['content'] ?? '';
          final upvotes = post['upvotes'] ?? 0;
          final upvotedBy = List<String>.from(post['upvotedBy'] ?? []);
          final isUpvoted = upvotedBy.contains(_userId);
          final replies = List<Map<String, dynamic>>.from(
            (post['replies'] ?? []).map((r) => r as Map<String, dynamic>),
          );
          final createdBy = post['createdBy'];
          final authorName = createdBy is Map
              ? createdBy['name'] ?? 'Unknown'
              : 'Unknown';
          final authorRole = createdBy is Map
              ? createdBy['role'] ?? 'student'
              : 'student';
          final isPinned = post['isPinned'] ?? false;
          final isLocked = post['isLocked'] ?? false;
          final createdById = createdBy is Map ? createdBy['_id'] ?? '' : '';
          final isOwner = createdById == _userId;

          return Column(
            children: [
              // Post content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshPost,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges
                        Row(
                          children: [
                            if (isPinned)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PINNED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (isPinned && isLocked) const SizedBox(width: 8),
                            if (isLocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LOCKED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (isPinned || isLocked) const SizedBox(height: 12),

                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Author info
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: authorRole == 'educator'
                                  ? Colors.deepPurple
                                  : Colors.blue,
                              child: Text(
                                authorName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  authorRole == 'educator'
                                      ? 'Educator'
                                      : 'Student',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Content
                        Text(content, style: const TextStyle(fontSize: 16)),

                        const SizedBox(height: 20),

                        // Upvote button
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _upvotePost,
                              icon: Icon(
                                isUpvoted
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                              ),
                              label: Text('$upvotes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isUpvoted
                                    ? Colors.blue[100]
                                    : Colors.grey[200],
                                foregroundColor: isUpvoted
                                    ? Colors.blue
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Delete button for owner (if not educator)
                            if (isOwner && _userRole != 'educator')
                              TextButton.icon(
                                onPressed: _deletePost,
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),

                        const Divider(height: 32),

                        // Replies section
                        Text(
                          'Replies (${replies.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Replies list
                        if (replies.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No replies yet'),
                            ),
                          )
                        else
                          ...replies.map((reply) {
                            final replyId = reply['_id'] ?? '';
                            return _buildReplyCard(reply, replyId);
                          }),
                      ],
                    ),
                  ),
                ),
              ),

              // Reply input (if not locked)
              if (!isLocked)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: const InputDecoration(
                            hintText: 'Write a reply...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          maxLines: null,
                          enabled: !_isSubmitting,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isSubmitting ? null : _addReply,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.red[50],
                  child: const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This post is locked. No new replies allowed.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Build reply card
  Widget _buildReplyCard(Map<String, dynamic> reply, String replyId) {
    final message = reply['message'] ?? '';
    final userId = reply['userId'];
    final userName = userId is Map ? userId['name'] ?? 'Unknown' : 'Unknown';
    final userRole = userId is Map ? userId['role'] ?? 'student' : 'student';
    final replyUserId = userId is Map ? userId['_id'] ?? '' : '';
    final isReplyOwner = replyUserId == _userId;
    final canDelete = _userRole == 'educator' || isReplyOwner;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: userRole == 'educator'
                      ? Colors.deepPurple
                      : Colors.blue,
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userRole == 'educator' ? 'Educator' : 'Student',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Delete button for educator or reply owner
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _deleteReply(replyId),
                    tooltip: 'Delete reply',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}
