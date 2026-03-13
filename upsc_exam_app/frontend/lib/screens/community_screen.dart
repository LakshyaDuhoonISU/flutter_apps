// Community Screen
// Displays community forum posts

import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late Future<List<dynamic>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
  }

  // Fetch community posts
  Future<List<dynamic>> _fetchPosts() async {
    try {
      final response = await ApiService.get('/community');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'] as List;
      } else {
        throw Exception(data['message'] ?? 'Failed to load posts');
      }
    } catch (e) {
      throw Exception('Error loading posts: $e');
    }
  }

  // Refresh posts
  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = _fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Forum'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: FutureBuilder<List<dynamic>>(
          future: _postsFuture,
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
                      onPressed: _refreshPosts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Success state
            final posts = snapshot.data!;

            // No posts
            if (posts.isEmpty) {
              return const Center(
                child: Text('No posts yet', style: TextStyle(fontSize: 16)),
              );
            }

            // Display posts
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildPostCard(post);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
          // Refresh if post was created
          if (result == true) {
            _refreshPosts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build post card
  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['_id'] ?? '';
    final title = post['title'] ?? 'No Title';
    final content = post['content'] ?? '';
    final upvotes = post['upvotes'] ?? 0;
    final repliesCount = (post['replies'] as List?)?.length ?? 0;
    final createdBy = post['createdBy'];
    final authorName = createdBy is Map
        ? createdBy['name'] ?? 'Unknown'
        : 'Unknown';
    final authorRole = createdBy is Map
        ? createdBy['role'] ?? 'student'
        : 'student';
    final isPinned = post['isPinned'] ?? false;
    final isLocked = post['isLocked'] ?? false;
    final category = post['category'] ?? 'General Discussion';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                PostDetailScreen(postId: postId, postTitle: title),
          ),
        );
        // Refresh if post was deleted
        if (result == true) {
          _refreshPosts();
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        color: isPinned ? Colors.yellow[50] : null,
        child: Padding(
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
              if (isPinned || isLocked) const SizedBox(height: 8),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Content (truncated)
              Text(
                content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 12),

              // Author and stats
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: authorRole == 'educator'
                        ? Colors.deepPurple
                        : Colors.blue,
                    child: Text(
                      authorName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    authorName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '• ${authorRole == 'educator' ? 'Educator' : 'Student'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text('$upvotes', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text('$repliesCount', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
