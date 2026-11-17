import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HermesConfig {
  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final int maxIterations;
  final bool enableTools;
  final bool enableSkills;
  final bool enableMemory;
  final Color accentColor;

  const HermesConfig({
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.model = 'gpt-4o-mini',
    this.temperature = 0.3,
    this.maxTokens = 8192,
    this.maxIterations = 10,
    this.enableTools = true,
    this.enableSkills = true,
    this.enableMemory = true,
    this.accentColor = const Color(0xFF7aa2f7),
  });

  factory HermesConfig.fromJson(Map<String, dynamic> json) {
    return HermesConfig(
      baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? 'gpt-4o-mini',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
      maxTokens: json['maxTokens'] as int? ?? 8192,
      maxIterations: json['maxIterations'] as int? ?? 10,
      enableTools: json['enableTools'] as bool? ?? true,
      enableSkills: json['enableSkills'] as bool? ?? true,
      enableMemory: json['enableMemory'] as bool? ?? true,
      accentColor: json['accentColor'] != null
          ? Color(int.parse(
              (json['accentColor'] as String).replaceFirst('#', ''),
              radix: 16,
            ) | 0xFF000000)
          : const Color(0xFF7aa2f7),
    );
  }

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'maxIterations': maxIterations,
        'enableTools': enableTools,
        'enableSkills': enableSkills,
        'enableMemory': enableMemory,
        'accentColor': '#${accentColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      };

  HermesConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    int? maxIterations,
    bool? enableTools,
    bool? enableSkills,
    bool? enableMemory,
    Color? accentColor,
  }) {
    return HermesConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      maxIterations: maxIterations ?? this.maxIterations,
      enableTools: enableTools ?? this.enableTools,
      enableSkills: enableSkills ?? this.enableSkills,
      enableMemory: enableMemory ?? this.enableMemory,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ConfigManager extends ChangeNotifier {
  HermesConfig _config = const HermesConfig();
  static const String _storageKey = 'hermes_config';

  HermesConfig get config => _config;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        _config = HermesConfig.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
  }

  Future<void> updateConfig(HermesConfig newConfig) async {
    _config = newConfig;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_config.toJson()));
    } catch (e) {
      debugPrint('Error saving config: $e');
    }
  }

  Future<void> reset() async {
    _config = const HermesConfig();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error resetting config: $e');
    }
  }
}