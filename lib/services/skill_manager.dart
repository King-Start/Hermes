import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class Skill {
  final String name;
  final String description;
  final String category;
  final String version;
  final String content;
  final List<String> tools;

  const Skill({
    required this.name,
    required this.description,
    this.category = 'general',
    this.version = '1.0.0',
    this.content = '',
    this.tools = const [],
  });
}

class SkillManager extends ChangeNotifier {
  final List<Skill> _skills = [];
  List<Skill> get skills => List.unmodifiable(_skills);

  static const String _skillsDir = 'skills';

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

  Future<void> _loadSkills() async {
    _skills.clear();

    // Load built-in skills from assets
    try {
      final content = await rootBundle.loadString('assets/skills/default-assistant.md');
      _skills.add(_parseSkill(content, 'default-assistant'));
    } catch (_) {}

    // Load user skills from documents dir
    try {
      final dir = await _getSkillsDir();
      final files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      for (final file in files) {
        try {
          final content = file.readAsStringSync();
          final name = file.uri.pathSegments.last.replaceAll('.md', '');
          _skills.add(_parseSkill(content, name));
        } catch (_) {}
      }
    } catch (_) {}

    notifyListeners();
  }

  Skill _parseSkill(String content, String fallbackName) {
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
            final value = line
                .substring(colonIndex + 1)
                .trim()
                .replaceAll('"', '')
                .replaceAll("'", '');

            switch (key) {
              case 'name': name = value; break;
              case 'description': description = value; break;
              case 'category': category = value; break;
              case 'version': version = value; break;
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
    );
  }

  Skill? getSkill(String name) {
    try {
      return _skills.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }

  List<Skill> getSkillsByCategory(String category) {
    return _skills.where((s) => s.category == category).toList();
  }

  List<String> getCategories() {
    return _skills.map((s) => s.category).toSet().toList();
  }

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
    } catch (e) {
      debugPrint('Error creating skill: $e');
    }

    _skills.add(skill);
    notifyListeners();
    return skill;
  }

  Future<void> deleteSkill(String name) async {
    _skills.removeWhere((s) => s.name == name);
    notifyListeners();

    try {
      final dir = await _getSkillsDir();
      final file = File('${dir.path}/$name.md');
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Error deleting skill: $e');
    }
  }
}