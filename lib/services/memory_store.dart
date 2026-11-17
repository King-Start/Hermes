import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent memory store
class MemoryStore extends ChangeNotifier {
  String _userProfile = '';
  String _agentMemory = '';

  String get userProfile => _userProfile;
  String get agentMemory => _agentMemory;

  static const String _userKey = 'hermes_user_profile';
  static const String _agentKey = 'hermes_agent_memory';

  /// Load memory from storage
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

  /// Save user profile
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

  /// Append to user profile
  Future<void> appendUserProfile(String addition) async {
    final current = _userProfile;
    final newContent = current.isEmpty ? addition : '$current\n\n$addition';
    await setUserProfile(newContent);
  }

  /// Save agent memory
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

  /// Append to agent memory
  Future<void> appendAgentMemory(String addition) async {
    final current = _agentMemory;
    final newContent = current.isEmpty ? addition : '$current\n\n$addition';
    await setAgentMemory(newContent);
  }

  /// Clear user profile
  Future<void> clearUserProfile() async {
    await setUserProfile('');
  }

  /// Clear agent memory
  Future<void> clearAgentMemory() async {
    await setAgentMemory('');
  }

  /// Clear all memory
  Future<void> clearAll() async {
    await clearUserProfile();
    await clearAgentMemory();
  }
}