import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/chat.dart';

/// Session manager for conversation history
class SessionManager extends ChangeNotifier {
  final List<Session> _sessions = [];
  Session? _currentSession;

  List<Session> get sessions => List.unmodifiable(_sessions);
  Session? get currentSession => _currentSession;

  static const String _sessionDir = 'sessions';

  /// Initialize session directory
  Future<void> init() async {
    try {
      final dir = await _getSessionDir();
      await dir.create(recursive: true);
      await _loadSessions();
    } catch (e) {
      debugPrint('Error initializing sessions: $e');
    }
  }

  Future<Directory> _getSessionDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/$_sessionDir');
  }

  /// Load all sessions
  Future<void> _loadSessions() async {
    try {
      final dir = await _getSessionDir();
      final files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      _sessions.clear();
      for (final file in files) {
        try {
          final content = file.readAsStringSync();
          final json = jsonDecode(content) as Map<String, dynamic>;
          _sessions.add(Session.fromJson(json));
        } catch (e) {
          debugPrint('Error loading session file: ${file.path}');
        }
      }

      // Sort by updated time, most recent first
      _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  /// Create new session
  Session createSession({String title = 'New Chat'}) {
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );
    _sessions.insert(0, session);
    _currentSession = session;
    notifyListeners();
    return session;
  }

  /// Load session by ID
  Session? loadSession(String id) {
    final session = _sessions.firstWhere(
      (s) => s.id == id,
      orElse: () => _currentSession ?? createSession(),
    );
    _currentSession = session;
    notifyListeners();
    return session;
  }

  /// Save current session
  Future<void> saveCurrentSession() async {
    if (_currentSession == null) return;

    try {
      final dir = await _getSessionDir();
      final file = File('${dir.path}/${_currentSession!.id}.json');
      await file.writeAsString(jsonEncode(_currentSession!.toJson()));

      // Update timestamp
      _currentSession = _currentSession!.copyWith(updatedAt: DateTime.now());
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// Add message to current session
  void addMessage(ChatMessage message) {
    if (_currentSession == null) {
      createSession();
    }

    final messages = List<ChatMessage>.from(_currentSession!.messages);
    messages.add(message);
    _currentSession = _currentSession!.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Update last message
  void updateLastMessage(ChatMessage updatedMessage) {
    if (_currentSession == null || _currentSession!.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(_currentSession!.messages);
    messages[messages.length - 1] = updatedMessage;
    _currentSession = _currentSession!.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Delete session
  Future<void> deleteSession(String id) async {
    try {
      final dir = await _getSessionDir();
      final file = File('${dir.path}/$id.json');
      if (await file.exists()) {
        await file.delete();
      }

      _sessions.removeWhere((s) => s.id == id);
      if (_currentSession?.id == id) {
        _currentSession = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  /// Clear all messages in current session
  void clearCurrentSession() {
    if (_currentSession == null) return;

    _currentSession = _currentSession!.copyWith(
      messages: [],
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Rename session
  void renameSession(String id, String newTitle) {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    _sessions[index] = _sessions[index].copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );

    if (_currentSession?.id == id) {
      _currentSession = _sessions[index];
    }
    notifyListeners();
  }
}