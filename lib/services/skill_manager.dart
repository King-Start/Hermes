import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Skill model
class Skill {
  final String name;
  final String description;
  final String category;
  final String version;
  final String content;
  final String path;
  final List<String> tools;

  const Skill({
    required this.name,
    required this.description,
    this.category = 'general',
    this.version = '1.0.0',
    this.content = '',
    this.path = '',
    this.tools = const [],
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      version: json['version'] as String? ?? '1.0.0',
      content: json['content'] as String? ?? '',
      path: json['path'] as String? ?? '',
      tools: json['tools'] != null
          ? (json['tools'] as List).cast<String>()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': category,
        'version': version,
        'content': content,
        'path': path,
        'tools': tools,
      };
}

/// Skill manager
class SkillManager extends ChangeNotifier {
  final List<Skill> _skills = [];
  List<Skill> get skills => List.unmodifiable(_skills);

  static const String _skillsDir = 'skills';

  /// Initialize skills
  Future<void> init() async {
    try {
      final dir = await _getSkillsDir();
      await dir.create(recursive: true);
      await _loadSkills();
    } catch (e) {
      debugPrint('Error initializing skills: $e');
    }
  }

  Future<Directory> _getSkillsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/$_skillsDir');
  }

  /// Load all skills
  Future<void> _loadSkills() async {
    try {
      _skills.clear();

      // Load built-in skills from assets
      final assetSkill = await rootBundle.loadString('assets/skills/default-assistant.md');
      final parsed = _parseSkillMarkdown(assetSkill, 'default-assistant');
      _skills.add(parsed);

      // Load user skills from directory
      final dir = await _getSkillsDir();
      final files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      for (final file in files) {
        try {
          final content = file.readAsStringSync();
          final name = file.uri.pathSegments.last.replaceAll('.md', '');
          final skill = _parseSkillMarkdown(content, name);
          _skills.add(skill);
        } catch (e) {
          debugPrint('Error loading skill file: ${file.path}');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading skills: $e');
    }
  }

  /// Parse markdown with YAML frontmatter
  Skill _parseSkillMarkdown(String content, String fallbackName) {
    String name = fallbackName;
    String description = '';
    String category = 'general';
    String version = '1.0.0';
    String body = content;

    if (content.startsWith('---')) {
      final parts = content.split('---');
      if (parts.length >= 3) {
        final frontmatter = parts[1];
        body = parts.sublist(2).join('---').trim();

        for (final line in frontmatter.split('\n')) {
          if (line.contains(':')) {
            final colonIndex = line.indexOf(':');
            final key = line.substring(0, colonIndex).trim();
            final value = line.substring(colonIndex + 1).trim();
            final cleanValue = value.replaceAll('"', '').replaceAll("'", '');

            switch (key) {
              case 'name':
                name = cleanValue;
                break;
              case 'description':
                description = cleanValue;
                break;
              case 'category':
                category = cleanValue;
                break;
              case 'version':
                version = cleanValue;
                break;
            }
          }
        }
      }
    }

    return Skill(
      name: name,
      description: description,
      category: category,
      version: version,
      content: body,
      path: '',
    );
  }

  /// Get skill by name
  Skill? getSkill(String name) {
    try {
      return _skills.firstWhere((s) => s.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Create new skill
  Future<Skill> createSkill({
    required String name,
    required String content,
    String category = 'general',
  }) async {
    final skill = Skill(
      name: name,
      description: content.split('\n').first.replaceAll('# ', ''),
      category: category,
      content: content,
    );

    try {
      final dir = await _getSkillsDir();
      final file = File('${dir.path}/$name.md');
      await file.writeAsString(content);

      _skills.add(skill);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating skill: $e');
    }

    return skill;
  }

  /// Delete skill
  Future<void> deleteSkill(String name) async {
    final index = _skills.indexWhere((s) => s.name == name);
    if (index == -1) return;

    _skills.removeAt(index);
    notifyListeners();

    try {
      final dir = await _getSkillsDir();
      final file = File('${dir.path}/$name.md');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting skill file: $e');
    }
  }

  /// Get skills by category
  List<Skill> getSkillsByCategory(String category) {
    return _skills.where((s) => s.category == category).toList();
  }

  /// Get all categories
  List<String> getCategories() {
    return _skills.map((s) => s.category).toSet().toList();
  }
}