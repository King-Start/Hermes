import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Persistent memory store (user profile + agent notes)
class MemoryStore extends ChangeNotifier {
  String _userProfile = '';
  String _agentMemory = '';

  String get userProfile => _userProfile;
  String get agentMemory => _agentMemory;

  static const String _userKey = 'hermes_user_profile';
  static const String _agentKey = 'hermes_agent_memory';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userProfile = prefs.getString(_userKey) ?? '';
      _agentMemory = prefs.getString(_agentKey) ?? '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading memory: $e');
    }
  }

  Future<void> setUserProfile(String content) async {
    _userProfile = content;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, content);
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  Future<void> appendUserProfile(String addition) async {
    final current = _userProfile;
    final newContent = current.isEmpty ? addition : '$current\n\n$addition';
    await setUserProfile(newContent);
  }

  Future<void> setAgentMemory(String content) async {
    _agentMemory = content;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_agentKey, content);
    } catch (e) {
      debugPrint('Error saving agent memory: $e');
    }
  }

  Future<void> appendAgentMemory(String addition) async {
    final current = _agentMemory;
    final newContent = current.isEmpty ? addition : '$current\n\n$addition';
    await setAgentMemory(newContent);
  }

  Future<void> clearUser() async => setUserProfile('');
  Future<void> clearAgent() async => setAgentMemory('');
  Future<void> clearAll() async {
    await clearUser();
    await clearAgent();
  }
}

/// Session manager for conversation history
class SessionManager extends ChangeNotifier {
  final List<Session> _sessions = [];
  Session? _currentSession;

  List<Session> get sessions => List.unmodifiable(_sessions);
  Session? get currentSession => _currentSession;

  static const String _sessionDir = 'sessions';

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
          final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          _sessions.add(Session.fromJson(json));
        } catch (_) {}
      }

      _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

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

  Session? loadSession(String id) {
    try {
      _currentSession = _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      _currentSession = null;
    }
    notifyListeners();
    return _currentSession;
  }

  Future<void> saveCurrentSession() async {
    if (_currentSession == null) return;

    try {
      final dir = await _getSessionDir();
      final file = File('${dir.path}/${_currentSession!.id}.json');
      await file.writeAsString(jsonEncode(_currentSession!.toJson()));

      _currentSession = _currentSession!.copyWith(updatedAt: DateTime.now());
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  void addMessage(ChatMessage message) {
    if (_currentSession == null) createSession();

    final messages = List<ChatMessage>.from(_currentSession!.messages);
    messages.append(message);
    _currentSession = _currentSession!.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void updateLastMessage(ChatMessage updated) {
    if (_currentSession == null || _currentSession!.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(_currentSession!.messages);
    messages[messages.length - 1] = updated;
    _currentSession = _currentSession!.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    try {
      final dir = await _getSessionDir();
      final file = File('${dir.path}/$id.json');
      if (await file.exists()) await file.delete();
    } catch (_) {}

    _sessions.removeWhere((s) => s.id == id);
    if (_currentSession?.id == id) _currentSession = null;
    notifyListeners();
  }

  void clearCurrentSession() {
    if (_currentSession == null) return;
    _currentSession = _currentSession!.copyWith(
      messages: [],
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void renameSession(String id, String newTitle) {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    _sessions[index] = _sessions[index].copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );

    if (_currentSession?.id == id) _currentSession = _sessions[index];
    notifyListeners();
  }
}