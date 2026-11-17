import 'package:flutter/foundation.dart';

class ToolParameter {
  final String name;
  final String type;
  final String description;
  final bool required;

  const ToolParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = true,
  });

  Map<String, dynamic> toJsonSchema() => {
        'type': type,
        'description': description,
      };
}

class Tool {
  final String name;
  final String description;
  final List<ToolParameter> parameters;
  final Future<dynamic> Function(Map<String, dynamic>)? onExecute;

  const Tool({
    required this.name,
    required this.description,
    this.parameters = const [],
    this.onExecute,
  });

  Map<String, dynamic> toOpenAiFunction() {
    final properties = <String, dynamic>{};
    final required = <String>[];

    for (final param in parameters) {
      properties[param.name] = param.toJsonSchema();
      if (param.required) required.add(param.name);
    }

    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': properties,
          'required': required,
        },
      },
    };
  }

  Future<dynamic> execute(Map<String, dynamic> args) async {
    if (onExecute != null) return await onExecute!(args);
    return 'Tool "$name" executed with args: $args';
  }
}

class ToolRegistry extends ChangeNotifier {
  final Map<String, Tool> _tools = {};
  Map<String, Tool> get tools => Map.unmodifiable(_tools);
  List<String> get toolNames => _tools.keys.toList();
  int get length => _tools.length;

  void register(Tool tool) {
    _tools[tool.name] = tool;
    notifyListeners();
  }

  void registerAll(List<Tool> tools) {
    for (final t in tools) _tools[t.name] = t;
    notifyListeners();
  }

  Tool? getTool(String name) => _tools[name];

  List<Map<String, dynamic>> toOpenAiTools() {
    return _tools.values.map((t) => t.toOpenAiFunction()).toList();
  }

  Future<dynamic> executeTool(String name, Map<String, dynamic> args) async {
    final tool = _tools[name];
    if (tool == null) throw Exception('Tool not found: $name');
    return await tool.execute(args);
  }

  void clear() {
    _tools.clear();
    notifyListeners();
  }
}

class BuiltInTools {
  static List<Tool> getAll() => [
        Tool(
          name: 'web_search',
          description: 'Search the web via DuckDuckGo',
          parameters: [
            ToolParameter(
                name: 'query', type: 'string', description: 'Search query'),
          ],
          onExecute: (args) async =>
              'Web search would run here. Query: ${args['query']}',
        ),
        Tool(
          name: 'memory_read',
          description: 'Read persistent memory (user profile or agent notes)',
          parameters: [
            ToolParameter(
                name: 'target',
                type: 'string',
                description: 'user or agent'),
          ],
        ),
        Tool(
          name: 'memory_write',
          description: 'Write to persistent memory',
          parameters: [
            ToolParameter(
                name: 'target',
                type: 'string',
                description: 'user or agent'),
            ToolParameter(
                name: 'content',
                type: 'string',
                description: 'Content to write'),
          ],
        ),
        Tool(
          name: 'skills_list',
          description: 'List available skills',
          parameters: [],
        ),
        Tool(
          name: 'skills_view',
          description: 'View a specific skill',
          parameters: [
            ToolParameter(
                name: 'name',
                type: 'string',
                description: 'Skill name'),
          ],
        ),
      ];
}