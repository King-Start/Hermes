import 'package:flutter/foundation.dart';

/// Tool parameter definition
class ToolParameter {
  final String name;
  final String type;
  final String description;
  final bool required;
  final dynamic defaultValue;

  const ToolParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = true,
    this.defaultValue,
  });

  Map<String, dynamic> toJsonSchema() {
    final schema = <String, dynamic>{
      'type': type,
      'description': description,
    };
    if (defaultValue != null) {
      schema['default'] = defaultValue;
    }
    return schema;
  }
}

/// Tool definition
class Tool {
  final String name;
  final String description;
  final List<ToolParameter> parameters;
  final Function(Map<String, dynamic>) onExecute;

  const Tool({
    required this.name,
    required this.description,
    this.parameters = const [],
    required this.onExecute,
  });

  /// Convert to OpenAI function format
  Map<String, dynamic> toOpenAiFunction() {
    final properties = <String, dynamic>{};
    final required = <String>[];

    for (final param in parameters) {
      properties[param.name] = param.toJsonSchema();
      if (param.required) {
        required.add(param.name);
      }
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

  /// Execute the tool with given arguments
  Future<dynamic> execute(Map<String, dynamic> args) async {
    return await onExecute(args);
  }
}

/// Tool registry
class ToolRegistry extends ChangeNotifier {
  final Map<String, Tool> _tools = {};
  Map<String, Tool> get tools => Map.unmodifiable(_tools);
  List<String> get toolNames => _tools.keys.toList();

  /// Register a tool
  void register(Tool tool) {
    _tools[tool.name] = tool;
    notifyListeners();
  }

  /// Register multiple tools
  void registerAll(List<Tool> tools) {
    for (final tool in tools) {
      _tools[tool.name] = tool;
    }
    notifyListeners();
  }

  /// Get tool by name
  Tool? getTool(String name) => _tools[name];

  /// Check if tool exists
  bool hasTool(String name) => _tools.containsKey(name);

  /// Remove tool
  void unregister(String name) {
    _tools.remove(name);
    notifyListeners();
  }

  /// Get all tools as OpenAI format
  List<Map<String, dynamic>> toOpenAiTools() {
    return _tools.values.map((t) => t.toOpenAiFunction()).toList();
  }

  /// Execute tool by name
  Future<dynamic> executeTool(String name, Map<String, dynamic> args) async {
    final tool = _tools[name];
    if (tool == null) {
      throw Exception('Tool not found: $name');
    }
    return await tool.execute(args);
  }

  /// Clear all tools
  void clear() {
    _tools.clear();
    notifyListeners();
  }

  /// Get tool count
  int get length => _tools.length;
}

/// Built-in tools factory
class BuiltInTools {
  static List<Tool> getAll() {
    return [
      _createFileReadTool(),
      _createFileWriteTool(),
      _createFileListTool(),
      _createTerminalTool(),
      _createWebSearchTool(),
      _createMemoryTool(),
      _createSkillTool(),
    ];
  }

  static Tool _createFileReadTool() {
    return Tool(
      name: 'file_read',
      description: 'Read the contents of a text file',
      parameters: [
        ToolParameter(
          name: 'path',
          type: 'string',
          description: 'File path to read',
          required: true,
        ),
      ],
      onExecute: (args) async {
        // Android: use path_provider to access files
        return 'File reading will be implemented natively on Android';
      },
    );
  }

  static Tool _createFileWriteTool() {
    return Tool(
      name: 'file_write',
      description: 'Write content to a file',
      parameters: [
        ToolParameter(
          name: 'path',
          type: 'string',
          description: 'File path to write',
          required: true,
        ),
        ToolParameter(
          name: 'content',
          type: 'string',
          description: 'Content to write',
          required: true,
        ),
      ],
      onExecute: (args) async {
        return 'File writing will be implemented natively on Android';
      },
    );
  }

  static Tool _createFileListTool() {
    return Tool(
      name: 'file_list',
      description: 'List files in a directory',
      parameters: [
        ToolParameter(
          name: 'path',
          type: 'string',
          description: 'Directory path',
          required: true,
        ),
      ],
      onExecute: (args) async {
        return 'File listing will be implemented natively on Android';
      },
    );
  }

  static Tool _createTerminalTool() {
    return Tool(
      name: 'terminal',
      description: 'Execute a shell command (requires Android root or specific permissions)',
      parameters: [
        ToolParameter(
          name: 'command',
          type: 'string',
          description: 'Command to execute',
          required: true,
        ),
      ],
      onExecute: (args) async {
        return 'Terminal execution requires Android root or specific permissions';
      },
    );
  }

  static Tool _createWebSearchTool() {
    return Tool(
      name: 'web_search',
      description: 'Search the web',
      parameters: [
        ToolParameter(
          name: 'query',
          type: 'string',
          description: 'Search query',
          required: true,
        ),
      ],
      onExecute: (args) async {
        return 'Web search requires internet permission';
      },
    );
  }

  static Tool _createMemoryTool() {
    return Tool(
      name: 'memory',
      description: 'Read or write persistent memory',
      parameters: [
        ToolParameter(
          name: 'action',
          type: 'string',
          description: 'Action: read, write, append, clear',
          required: true,
        ),
        ToolParameter(
          name: 'target',
          type: 'string',
          description: 'Target: user or agent',
          required: true,
        ),
        ToolParameter(
          name: 'content',
          type: 'string',
          description: 'Content to write/append',
          required: false,
        ),
      ],
      onExecute: (args) async {
        return 'Memory operations will be handled by the app';
      },
    );
  }

  static Tool _createSkillTool() {
    return Tool(
      name: 'skills',
      description: 'List or view available skills',
      parameters: [
        ToolParameter(
          name: 'action',
          type: 'string',
          description: 'Action: list, view',
          required: true,
        ),
        ToolParameter(
          name: 'name',
          type: 'string',
          description: 'Skill name (for view)',
          required: false,
        ),
      ],
      onExecute: (args) async {
        return 'Skills will be listed by the app';
      },
    );
  }
}