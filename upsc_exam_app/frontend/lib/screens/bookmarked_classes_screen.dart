// Bookmarked Classes Screen (My Notes)
// Shows all bookmarked videos for students with embedded video player

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/course_service.dart';

// Conditional imports for web
import 'dart:ui_web' as ui_web show platformViewRegistry;
import 'dart:html' show IFrameElement;

class BookmarkedClassesScreen extends StatefulWidget {
  const BookmarkedClassesScreen({Key? key}) : super(key: key);

  @override
  State<BookmarkedClassesScreen> createState() =>
      _BookmarkedClassesScreenState();
}

class _BookmarkedClassesScreenState extends State<BookmarkedClassesScreen> {
  late Future<List<Map<String, dynamic>>> _bookmarksFuture;
  Set<String> _bookmarkedClassIds = {};

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    _bookmarksFuture = CourseService.getBookmarkedClasses().then((bookmarks) {
      setState(() {
        _bookmarkedClassIds = bookmarks
            .map((cls) => cls['_id'].toString())
            .toSet();
      });
      return bookmarks;
    });
  }

  // Remove bookmark
  Future<void> _removeBookmark(String classId) async {
    try {
      await CourseService.unbookmarkClass(classId);
      setState(() {
        _bookmarkedClassIds.remove(classId);
        _loadBookmarks(); // Reload the list
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark removed'),
            duration: Duration(seconds: 1),
          ),
        );
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
  void _showVideoDialog(String videoUrl, String title, String classId) {
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
      builder: (context) =>
          _VideoPlayerDialog(videoId: videoId, title: title, classId: classId),
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

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _bookmarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadBookmarks();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final bookmarks = snapshot.data ?? [];

          if (bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarked videos yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark videos from your courses to access them here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final cls = bookmarks[index];
              return _buildBookmarkCard(cls);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookmarkCard(Map<String, dynamic> cls) {
    final classId = cls['_id'] ?? '';
    final title = cls['title'] ?? 'Untitled';
    final videoUrl = cls['videoUrl'] ?? '';
    final topic = cls['topicId'];
    final course = cls['courseId'];

    final topicTitle = topic != null ? topic['title'] : 'Unknown Topic';
    final courseTitle = course != null ? course['title'] : 'Unknown Course';
    final educatorName = course != null && course['educatorId'] != null
        ? course['educatorId']['name']
        : 'Unknown Educator';
    final thumbnail = course != null ? course['thumbnail'] : '';

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course and Topic Info Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                if (thumbnail.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      thumbnail,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 20),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Topic: $topicTitle',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Video Details
          ListTile(
            leading: const Icon(
              Icons.play_circle_filled,
              color: Colors.green,
              size: 32,
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'By $educatorName',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.amber),
                  onPressed: () => _removeBookmark(classId),
                  tooltip: 'Remove bookmark',
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: videoUrl.isNotEmpty
                      ? () => _showVideoDialog(videoUrl, title, classId)
                      : null,
                  tooltip: 'Play video',
                ),
              ],
            ),
            onTap: videoUrl.isNotEmpty
                ? () => _showVideoDialog(videoUrl, title, classId)
                : null,
          ),
        ],
      ),
    );
  }
}

// Video Player Dialog Widget with Notes
class _VideoPlayerDialog extends StatefulWidget {
  final String videoId;
  final String title;
  final String classId;

  const _VideoPlayerDialog({
    Key? key,
    required this.videoId,
    required this.title,
    required this.classId,
  }) : super(key: key);

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  String? _iframeViewType;
  List<Map<String, dynamic>> _notes = [];
  bool _isLoadingNotes = true;
  final _noteController = TextEditingController();
  String? _editingNoteId;
  bool _isHighlighted = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _iframeViewType = 'youtube-player-${widget.videoId}';
      // Register the view factory
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(_iframeViewType!, (
        int viewId,
      ) {
        final iframe = IFrameElement()
          ..src = 'https://www.youtube.com/embed/${widget.videoId}?autoplay=1'
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%'
          ..allow = 'autoplay; encrypted-media';
        return iframe;
      });
    }
    _loadNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await CourseService.getClassNotes(widget.classId);
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoadingNotes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNotes = false;
        });
      }
    }
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a note')));
      return;
    }

    try {
      final newNote = await CourseService.addClassNote(
        widget.classId,
        _noteController.text.trim(),
        isHighlighted: _isHighlighted,
      );

      if (mounted) {
        setState(() {
          _notes.add(newNote);
          _noteController.clear();
          _isHighlighted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note added'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateNote(String noteId) async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a note')));
      return;
    }

    try {
      final updatedNote = await CourseService.updateClassNote(
        widget.classId,
        noteId,
        _noteController.text.trim(),
        isHighlighted: _isHighlighted,
      );

      if (mounted) {
        setState(() {
          final index = _notes.indexWhere((n) => n['_id'] == noteId);
          if (index != -1) {
            _notes[index] = updatedNote;
          }
          _noteController.clear();
          _editingNoteId = null;
          _isHighlighted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CourseService.deleteClassNote(widget.classId, noteId);
        if (mounted) {
          setState(() {
            _notes.removeWhere((n) => n['_id'] == noteId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note deleted'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _startEditing(Map<String, dynamic> note) {
    setState(() {
      _editingNoteId = note['_id'];
      _noteController.text = note['content'];
      _isHighlighted = note['isHighlighted'] ?? false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingNoteId = null;
      _noteController.clear();
      _isHighlighted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Video Player
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              color: Colors.black,
              child: kIsWeb && _iframeViewType != null
                  ? HtmlElementView(viewType: _iframeViewType!)
                  : const Center(
                      child: Text(
                        'Video player is only available on web',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
            ),
            // Notes Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.note_add, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_notes.isNotEmpty)
                          Text(
                            '${_notes.length} note${_notes.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Add/Edit Note Form
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              hintText: _editingNoteId != null
                                  ? 'Edit your note...'
                                  : 'Add a note...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(8),
                              isDense: true,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tip: Select text and click highlight button to mark important parts',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Text highlight buttons
                              Tooltip(
                                message: 'Highlight selected text',
                                child: IconButton(
                                  icon: const Icon(Icons.highlight, size: 20),
                                  onPressed: _highlightSelectedText,
                                  color: Colors.amber[700],
                                ),
                              ),
                              Tooltip(
                                message: 'Remove highlight from selected text',
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.highlight_off,
                                    size: 20,
                                  ),
                                  onPressed: _removeHighlightFromSelectedText,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: _isHighlighted,
                                onChanged: (value) {
                                  setState(() {
                                    _isHighlighted = value ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Star note',
                                style: TextStyle(fontSize: 13),
                              ),
                              const Spacer(),
                              if (_editingNoteId != null) ...[
                                TextButton(
                                  onPressed: _cancelEditing,
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                              ],
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_editingNoteId != null) {
                                    _updateNote(_editingNoteId!);
                                  } else {
                                    _addNote();
                                  }
                                },
                                icon: Icon(
                                  _editingNoteId != null
                                      ? Icons.check
                                      : Icons.add,
                                ),
                                label: Text(
                                  _editingNoteId != null
                                      ? 'Update'
                                      : 'Add Note',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Notes List
                    Expanded(
                      child: _isLoadingNotes
                          ? const Center(child: CircularProgressIndicator())
                          : _notes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.note_outlined,
                                    size: 32,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No notes yet',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _notes.length,
                              itemBuilder: (context, index) {
                                final note = _notes[index];
                                final isHighlighted =
                                    note['isHighlighted'] ?? false;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: isHighlighted
                                      ? Colors.amber[50]
                                      : Colors.white,
                                  child: ListTile(
                                    leading: Icon(
                                      isHighlighted ? Icons.star : Icons.note,
                                      color: isHighlighted
                                          ? Colors.amber
                                          : Colors.grey,
                                    ),
                                    title: _buildRichTextContent(
                                      note['content'],
                                    ),
                                    subtitle: Text(
                                      _formatDate(note['createdAt']),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          onPressed: () => _startEditing(note),
                                          tooltip: 'Edit note',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteNote(note['_id']),
                                          tooltip: 'Delete note',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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

  // Highlight selected text in the note
  void _highlightSelectedText() {
    final selection = _noteController.selection;
    if (!selection.isValid || selection.start == selection.end) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select text to highlight'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final text = _noteController.text;
    final selectedText = text.substring(selection.start, selection.end);

    // Don't highlight if already highlighted
    if (selectedText.startsWith('[[') && selectedText.endsWith(']]')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text is already highlighted'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final beforeSelection = text.substring(0, selection.start);
    final afterSelection = text.substring(selection.end);

    setState(() {
      _noteController.text = '$beforeSelection[[$selectedText]]$afterSelection';
      // Move cursor after the highlighted text
      _noteController.selection = TextSelection.collapsed(
        offset: selection.start + selectedText.length + 4,
      );
    });
  }

  // Remove highlight from selected text
  void _removeHighlightFromSelectedText() {
    final selection = _noteController.selection;
    if (!selection.isValid || selection.start == selection.end) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select text to remove highlight'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final text = _noteController.text;
    final selectedText = text.substring(selection.start, selection.end);

    // Remove [[ and ]] markers
    if (selectedText.startsWith('[[') && selectedText.endsWith(']]')) {
      final unHighlightedText = selectedText.substring(
        2,
        selectedText.length - 2,
      );
      final beforeSelection = text.substring(0, selection.start);
      final afterSelection = text.substring(selection.end);

      setState(() {
        _noteController.text =
            '$beforeSelection$unHighlightedText$afterSelection';
        _noteController.selection = TextSelection.collapsed(
          offset: selection.start + unHighlightedText.length,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected text is not highlighted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Build rich text content with highlights
  Widget _buildRichTextContent(String content) {
    final List<TextSpan> spans = [];
    final RegExp highlightRegex = RegExp(r'\[\[([^\]]+)\]\]');
    int lastMatchEnd = 0;

    for (final match in highlightRegex.allMatches(content)) {
      // Add text before the highlight
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: content.substring(lastMatchEnd, match.start),
            style: const TextStyle(color: Colors.black),
          ),
        );
      }

      // Add highlighted text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            backgroundColor: Colors.yellow[300],
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(lastMatchEnd),
          style: const TextStyle(color: Colors.black),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      // Parse the UTC date and convert to IST (UTC + 5:30)
      final utcDate = DateTime.parse(dateStr).toUtc();
      final istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      final now = DateTime.now();
      final diff = now.difference(istDate);

      if (diff.inDays == 0) {
        return 'Today ${istDate.hour}:${istDate.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${istDate.day}/${istDate.month}/${istDate.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
