import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SocketService {
  static IO.Socket? _socket;
  static String? _token;

  /// Disconnect and destroy the existing socket (call on logout).
  static void disconnect() {
    if (_socket == null) return;
    // Call dispose() directly — NOT disconnect() first.
    // disconnect() queues an auto-reconnect; dispose() does a clean destroy
    // that cancels reconnection, preventing the old token from re-authenticating.
    _socket!.dispose();
    _socket = null;
    _token = null;
    // Remove the cached Manager so it cannot auto-reconnect with the old token.
    IO.cache.clear();
  }

  static Future<void> initialize(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final newToken = prefs.getString(tokenKey);
    final storedRole = prefs.getString(userRoleKey);
    final storedName = prefs.getString(userNameKey);

    print(
      'SocketService.initialize — token prefix: ${newToken?.substring(0, 20)}, role: $storedRole, name: $storedName',
    );

    if (newToken == null) {
      throw Exception('No authentication token found');
    }

    // If same user is already connected, reuse the socket
    if (_socket != null && _socket!.connected && _token == newToken) {
      return;
    }

    // Different user (or disconnected) — destroy old socket and reconnect
    if (_socket != null) {
      _socket!
          .dispose(); // dispose() cancels reconnection; don't call disconnect() first
      _socket = null;
      IO.cache
          .clear(); // remove stale Manager so it cannot ghost-reconnect with old token
    }

    _token = newToken;

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .enableForceNewConnection() // bypass the global Manager cache on each init
          .setAuth({'token': _token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket!.onError((error) {
      print('Socket error: $error');
    });
  }

  static IO.Socket? get socket => _socket;

  static void dispose() {
    disconnect();
  }

  static void joinClass(String classId) {
    _socket?.emit('join-class', classId);
  }

  static void leaveClass(String classId) {
    _socket?.emit('leave-class', classId);
  }

  // Chat events
  static void sendChat(String classId, String message) {
    _socket?.emit('send-chat', {'classId': classId, 'message': message});
  }

  static void deleteChat(String classId, String chatId) {
    _socket?.emit('delete-chat', {'classId': classId, 'chatId': chatId});
  }

  // Poll events
  static void createPoll(
    String classId,
    String question,
    List<String> options,
    int durationSeconds,
  ) {
    _socket?.emit('create-poll', {
      'classId': classId,
      'question': question,
      'options': options,
      'durationSeconds': durationSeconds,
    });
  }

  static void votePoll(String classId, String pollId, int optionIndex) {
    _socket?.emit('vote-poll', {
      'classId': classId,
      'pollId': pollId,
      'optionIndex': optionIndex,
    });
  }

  // Doubt events
  static void raiseDoubt(String classId, String question) {
    _socket?.emit('raise-doubt', {'classId': classId, 'question': question});
  }

  static void answerDoubt(String classId, String doubtId, String answer) {
    _socket?.emit('answer-doubt', {
      'classId': classId,
      'doubtId': doubtId,
      'answer': answer,
    });
  }

  static void deleteDoubt(String classId, String doubtId) {
    _socket?.emit('delete-doubt', {'classId': classId, 'doubtId': doubtId});
  }

  // Listen to events
  static void onEvent(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  static void offEvent(String event) {
    _socket?.off(event);
  }
}
