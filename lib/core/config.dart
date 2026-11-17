import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration settings for Hermes Agent
class HermesConfig {
  // LLM settings
  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final int maxIterations;

  // Theme
  final Color primaryColor;
  final Color accentColor;

  // Feature flags
  final bool enableTools;
  final bool enableSkills;
  final bool enableMemory;

  const HermesConfig({
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.model = 'gpt-4o-mini',
    this.temperature = 0.3,
    this.maxTokens = 8192,
    this.maxIterations = 10,
    this.primaryColor = const Color(0xFF1a1b26),
    this.accentColor = const Color(0xFF7aa2f7),
    this.enableTools = true,
    this.enableSkills = true,
    this.enableMemory = true,
  });

  factory HermesConfig.fromJson(Map<String, dynamic> json) {
    return HermesConfig(
      baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? 'gpt-4o-mini',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
      maxTokens: json['maxTokens'] as int? ?? 8192,
      maxIterations: json['maxIterations'] as int? ?? 10,
      primaryColor: Color(int.parse(
        (json['primaryColor'] as String? ?? '#1a1b26').replaceFirst('#', ''),
        radix: 16,
      )),
      accentColor: Color(int.parse(
        (json['accentColor'] as String? ?? '#7aa2f7').replaceFirst('#', ''),
        radix: 16,
      )),
      enableTools: json['enableTools'] as bool? ?? true,
      enableSkills: json['enableSkills'] as bool? ?? true,
      enableMemory: json['enableMemory'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'maxIterations': maxIterations,
        'primaryColor': '#${primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'accentColor': '#${accentColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'enableTools': enableTools,
        'enableSkills': enableSkills,
        'enableMemory': enableMemory,
      };

  HermesConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    int? maxIterations,
    Color? primaryColor,
    Color? accentColor,
    bool? enableTools,
    bool? enableSkills,
    bool? enableMemory,
  }) {
    return HermesConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      maxIterations: maxIterations ?? this.maxIterations,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      enableTools: enableTools ?? this.enableTools,
      enableSkills: enableSkills ?? this.enableSkills,
      enableMemory: enableMemory ?? this.enableMemory,
    );
  }
}

/// Configuration manager
class ConfigManager extends ChangeNotifier {
  HermesConfig _config;
  static const String _storageKey = 'hermes_config';

  ConfigManager() : _config = const HermesConfig();

  HermesConfig get config => _config;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        _config = HermesConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_config.toJson()));
    } catch (e) {
      debugPrint('Error saving config: $e');
    }
  }

  Future<void> updateConfig(HermesConfig newConfig) async {
    _config = newConfig;
    notifyListeners();
    await save();
  }

  Future<void> reset() async {
    _config = const HermesConfig();
    notifyListeners();
    await save();
  }
}

// Import for SharedPreferences