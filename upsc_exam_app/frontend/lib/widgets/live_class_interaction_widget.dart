import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/live_class_models.dart';
import '../services/socket_service.dart';
import 'dart:html' as html;

class LiveClassInteractionWidget extends StatefulWidget {
  final String classId;
  final String userRole;
  final String userId;

  /// Called when the backend signals the class has ended (live → recorded).
  final VoidCallback? onClassEnded;

  const LiveClassInteractionWidget({
    Key? key,
    required this.classId,
    required this.userRole,
    required this.userId,
    this.onClassEnded,
  }) : super(key: key);

  @override
  State<LiveClassInteractionWidget> createState() =>
      _LiveClassInteractionWidgetState();
}

class _LiveClassInteractionWidgetState extends State<LiveClassInteractionWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<LiveChat> _chats = [];
  final List<LivePoll> _polls = [];
  final List<LiveDoubt> _doubts = [];
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _doubtController = TextEditingController();
  bool _hasVoted = false;

  /// The currently running poll (if any).
  LivePoll? get _activePoll => _polls
      .where((p) => p.isActive && DateTime.now().isBefore(p.endsAt))
      .firstOrNull;

  /// Inserts or replaces a poll in [_polls] by ID.
  void _upsertPoll(LivePoll poll) {
    final idx = _polls.indexWhere((p) => p.id == poll.id);
    if (idx != -1) {
      _polls[idx] = poll;
    } else {
      _polls.insert(0, poll);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupSocketListeners();
    SocketService.joinClass(widget.classId);
  }

  void _setupSocketListeners() {
    // Chat listeners
    SocketService.onEvent('chat-history', (data) {
      if (!mounted) return;
      setState(() {
        _chats.clear();
        _chats.addAll(
          (data as List).map((chat) => LiveChat.fromJson(chat)).toList(),
        );
      });
    });

    SocketService.onEvent('new-chat', (data) {
      if (!mounted) return;
      setState(() {
        _chats.add(LiveChat.fromJson(data));
      });
    });

    SocketService.onEvent('chat-deleted', (data) {
      if (!mounted) return;
      setState(() {
        _chats.removeWhere((chat) => chat.id == data['chatId']);
      });
    });

    // Poll listeners

    // Full history on join (active + ended polls)
    SocketService.onEvent('polls-history', (data) {
      if (!mounted) return;
      setState(() {
        _polls.clear();
        _polls.addAll((data as List).map((p) => LivePoll.fromJson(p)).toList());
      });
    });

    // Legacy active-poll (kept for backwards compat, treated as upsert)
    SocketService.onEvent('active-poll', (data) {
      if (!mounted) return;
      setState(() {
        _upsertPoll(LivePoll.fromJson(data));
        _hasVoted = false;
      });
    });

    SocketService.onEvent('new-poll', (data) {
      if (!mounted) return;
      setState(() {
        _upsertPoll(LivePoll.fromJson(data));
        _hasVoted = false;
      });
    });

    // Educator receives full poll data (with vote counts) when they create a poll
    SocketService.onEvent('poll-created', (data) {
      if (!mounted) return;
      if (widget.userRole == 'educator') {
        setState(() {
          _upsertPoll(LivePoll.fromJson(data));
        });
      }
    });

    SocketService.onEvent('poll-ended', (data) {
      if (!mounted) return;
      setState(() {
        final idx = _polls.indexWhere((p) => p.id == data['pollId']);
        if (idx != -1) {
          _polls[idx] = _polls[idx].copyWith(isActive: false);
        }
      });
    });

    // Final results sent to educators after poll ends
    SocketService.onEvent('poll-results', (data) {
      if (!mounted) return;
      if (widget.userRole == 'educator') {
        setState(() {
          _upsertPoll(LivePoll.fromJson(data));
        });
      }
    });

    // Live vote count updates for educators while poll is active
    SocketService.onEvent('poll-update', (data) {
      if (!mounted) return;
      if (widget.userRole == 'educator') {
        setState(() {
          _upsertPoll(LivePoll.fromJson(data));
        });
      }
    });

    SocketService.onEvent('vote-recorded', (data) {
      if (!mounted) return;
      setState(() {
        _hasVoted = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vote recorded!')));
    });

    // Doubt listeners
    SocketService.onEvent('doubts-list', (data) {
      if (!mounted) return;
      setState(() {
        _doubts.clear();
        _doubts.addAll(
          (data as List).map((doubt) => LiveDoubt.fromJson(doubt)).toList(),
        );
      });
    });

    SocketService.onEvent('new-doubt', (data) {
      if (!mounted) return;
      setState(() {
        _doubts.insert(0, LiveDoubt.fromJson(data));
      });
    });

    SocketService.onEvent('doubt-raised', (data) {
      if (!mounted) return;
      setState(() {
        _doubts.insert(0, LiveDoubt.fromJson(data));
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Doubt submitted!')));
    });

    SocketService.onEvent('doubt-answered', (data) {
      if (!mounted) return;
      final answeredDoubt = LiveDoubt.fromJson(data);
      setState(() {
        final index = _doubts.indexWhere((d) => d.id == answeredDoubt.id);
        if (index != -1) {
          _doubts[index] = answeredDoubt;
        }
      });
    });

    // Educator's own view updates after they answer a doubt
    SocketService.onEvent('doubt-answer-recorded', (data) {
      if (!mounted) return;
      final answeredDoubt = LiveDoubt.fromJson(data);
      setState(() {
        final index = _doubts.indexWhere((d) => d.id == answeredDoubt.id);
        if (index != -1) {
          _doubts[index] = answeredDoubt;
        }
      });
    });

    SocketService.onEvent('doubt-deleted', (data) {
      if (!mounted) return;
      setState(() {
        _doubts.removeWhere((doubt) => doubt.id == data['doubtId']);
      });
    });

    SocketService.onEvent('error', (data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'An error occurred')),
      );
    });

    // Class ended — all live data has been cleared
    SocketService.onEvent('class-ended', (data) {
      if (!mounted) return;
      setState(() {
        _chats.clear();
        _polls.clear();
        _doubts.clear();
      });
      // Notify the parent dialog so it can close the player
      widget.onClassEnded?.call();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _doubtController.dispose();
    SocketService.leaveClass(widget.classId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(icon: Icon(Icons.chat_bubble), text: 'Chat'),
              Tab(icon: Icon(Icons.poll), text: 'Polls'),
              Tab(icon: Icon(Icons.question_answer), text: 'Doubts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildChatTab(), _buildPollTab(), _buildDoubtTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _chats.length,
            itemBuilder: (context, index) {
              final chat = _chats[index];
              final isEducator = chat.userRole == 'educator';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isEducator
                          ? Colors.deepPurple
                          : Colors.blue,
                      child: Text(
                        chat.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                chat.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isEducator
                                      ? Colors.deepPurple
                                      : Colors.black87,
                                ),
                              ),
                              if (isEducator)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'EDUCATOR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                DateFormat(
                                  'HH:mm',
                                ).format(chat.createdAt.toLocal()),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(chat.message),
                        ],
                      ),
                    ),
                    if (widget.userRole == 'educator')
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        onPressed: () {
                          SocketService.deleteChat(widget.classId, chat.id);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLength: 500,
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                color: Colors.deepPurple,
                onPressed: _sendChat,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendChat() {
    final message = _chatController.text.trim();
    if (message.isNotEmpty) {
      SocketService.sendChat(widget.classId, message);
      _chatController.clear();
    }
  }

  Widget _buildPollTab() {
    if (widget.userRole == 'educator') {
      return _buildEducatorPollView();
    } else {
      return _buildStudentPollView();
    }
  }

  Widget _buildEducatorPollView() {
    return Column(
      children: [
        Expanded(
          child: _polls.isEmpty
              ? const Center(child: Text('No polls yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _polls.length,
                  itemBuilder: (context, index) {
                    final poll = _polls[index];
                    final isRunning =
                        poll.isActive && DateTime.now().isBefore(poll.endsAt);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isRunning ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: isRunning
                            ? const BorderSide(
                                color: Colors.deepPurple,
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    poll.question,
                                    style: const TextStyle(
                                      fontSize: 15,
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
                                    color: isRunning
                                        ? Colors.green
                                        : Colors.grey[400],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isRunning ? 'LIVE' : 'ENDED',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildPollResultsInline(poll),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton.icon(
            onPressed: _activePoll != null ? null : _showCreatePollDialog,
            icon: const Icon(Icons.add),
            label: Text(
              _activePoll != null ? 'Poll in progress...' : 'Create Poll',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 235, 234, 237),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentPollView() {
    if (_polls.isEmpty) {
      return const Center(child: Text('No polls yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _polls.length,
      itemBuilder: (context, index) {
        final poll = _polls[index];
        final isRunning = poll.isActive && DateTime.now().isBefore(poll.endsAt);

        if (isRunning) {
          // Active poll — show voting card
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _hasVoted
                  ? Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Vote recorded!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          poll.question,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const Text('Waiting for results...'),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                poll.question,
                                style: const TextStyle(
                                  fontSize: 15,
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
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ends at: ${_formatTime(poll.endsAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...poll.options.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                SocketService.votePoll(
                                  widget.classId,
                                  poll.id,
                                  entry.key,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Text(entry.value.text),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
            ),
          );
        }

        // Ended poll — show results
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        poll.question,
                        style: const TextStyle(
                          fontSize: 15,
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
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ENDED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildPollResultsInline(poll),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
  }

  Widget _buildPollResultsInline(LivePoll poll) {
    final totalVotes = poll.options.fold<int>(
      0,
      (sum, option) => sum + option.votes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total votes: $totalVotes',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 8),
        ...poll.options.asMap().entries.map((entry) {
          final option = entry.value;
          final percentage = totalVotes > 0
              ? (option.votes / totalVotes * 100).toStringAsFixed(1)
              : '0.0';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(option.text)),
                    Text(
                      '${option.votes} ($percentage%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: totalVotes > 0 ? option.votes / totalVotes : 0,
                  backgroundColor: Colors.grey[300],
                  color: Colors.deepPurple,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Disable all iframes on the page so they don't steal keyboard focus
  void _disableIframes() {
    html.querySelectorAll('iframe').forEach((el) {
      (el as html.IFrameElement).style.pointerEvents = 'none';
    });
  }

  void _enableIframes() {
    html.querySelectorAll('iframe').forEach((el) {
      (el as html.IFrameElement).style.pointerEvents = 'auto';
    });
  }

  void _showCreatePollDialog() {
    final questionController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    int duration = 60;

    _disableIframes();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 200,
                ),
                const SizedBox(height: 16),
                ...optionControllers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: 'Option ${entry.key + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }).toList(),
                if (optionControllers.length < 5)
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        optionControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Option'),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: duration,
                  decoration: const InputDecoration(
                    labelText: 'Duration (seconds)',
                    border: OutlineInputBorder(),
                  ),
                  items: [30, 60, 90, 120, 180, 300].map((sec) {
                    return DropdownMenuItem(
                      value: sec,
                      child: Text('$sec seconds'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      duration = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final question = questionController.text.trim();
                final options = optionControllers
                    .map((c) => c.text.trim())
                    .where((text) => text.isNotEmpty)
                    .toList();

                if (question.isNotEmpty && options.length >= 2) {
                  SocketService.createPoll(
                    widget.classId,
                    question,
                    options,
                    duration,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    ).whenComplete(_enableIframes);
  }

  Widget _buildDoubtTab() {
    return Column(
      children: [
        Expanded(
          child: _doubts.isEmpty
              ? const Center(child: Text('No doubts yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _doubts.length,
                  itemBuilder: (context, index) {
                    final doubt = _doubts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    doubt.studentName,
                                    style: const TextStyle(
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
                                    color: doubt.status == 'answered'
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    doubt.status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (widget.userRole == 'educator')
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    color: Colors.red,
                                    onPressed: () {
                                      SocketService.deleteDoubt(
                                        widget.classId,
                                        doubt.id,
                                      );
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Q: ${doubt.question}',
                              style: const TextStyle(fontSize: 15),
                            ),
                            if (doubt.answer != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'A: ${doubt.answer}',
                                  style: TextStyle(color: Colors.green[900]),
                                ),
                              ),
                            ],
                            if (widget.userRole == 'educator' &&
                                doubt.status == 'pending')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showAnswerDoubtDialog(doubt),
                                  icon: const Icon(Icons.reply, size: 18),
                                  label: const Text('Answer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      217,
                                      215,
                                      220,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (widget.userRole == 'student')
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _doubtController,
                    decoration: const InputDecoration(
                      hintText: 'Ask your doubt...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLength: 500,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.deepPurple,
                  onPressed: _raiseDoubt,
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _raiseDoubt() {
    final question = _doubtController.text.trim();
    if (question.isNotEmpty) {
      SocketService.raiseDoubt(widget.classId, question);
      _doubtController.clear();
    }
  }

  void _showAnswerDoubtDialog(LiveDoubt doubt) {
    final answerController = TextEditingController();

    _disableIframes();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Answer Doubt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question: ${doubt.question}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: answerController,
              decoration: const InputDecoration(
                labelText: 'Your Answer',
                border: OutlineInputBorder(),
              ),
              maxLength: 1000,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final answer = answerController.text.trim();
              if (answer.isNotEmpty) {
                SocketService.answerDoubt(widget.classId, doubt.id, answer);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
