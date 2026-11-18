import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'shell.dart';
import 'skill_manager.dart';
import 'storage.dart';

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
  static List<Tool> getAll({
    required MemoryStore memory,
    required SkillManager skills,
  }) =>
      [
        Tool(
          name: 'run_shell',
          description:
              'Run a shell command (sh) on the Android device. Working dir is the app workspace.',
          parameters: [
            ToolParameter(
                name: 'command', type: 'string', description: 'Shell command'),
          ],
          onExecute: (a) => Shell.run('${a['command']}'),
        ),
        Tool(
          name: 'read_file',
          description: 'Read a text file (relative to the workspace)',
          parameters: [
            ToolParameter(name: 'path', type: 'string', description: 'File path'),
          ],
          onExecute: (a) => Shell.readFile('${a['path']}'),
        ),
        Tool(
          name: 'write_file',
          description: 'Write a text file (relative to the workspace)',
          parameters: [
            ToolParameter(name: 'path', type: 'string', description: 'File path'),
            ToolParameter(
                name: 'content', type: 'string', description: 'File content'),
          ],
          onExecute: (a) => Shell.writeFile('${a['path']}', '${a['content']}'),
        ),
        Tool(
          name: 'fetch_url',
          description: 'Download a web page or API response as text',
          parameters: [
            ToolParameter(name: 'url', type: 'string', description: 'http(s) URL'),
          ],
          onExecute: (a) async {
            final r = await http
                .get(Uri.parse('${a['url']}'))
                .timeout(const Duration(seconds: 30));
            final body = r.body;
            return 'HTTP ${r.statusCode}\n'
                '${body.length > 8000 ? body.substring(0, 8000) : body}';
          },
        ),
        Tool(
          name: 'memory_read',
          description: 'Read persistent memory (user profile or agent notes)',
          parameters: [
            ToolParameter(
                name: 'target', type: 'string', description: 'user or agent'),
          ],
          onExecute: (a) async =>
              a['target'] == 'user' ? memory.userProfile : memory.agentMemory,
        ),
        Tool(
          name: 'memory_write',
          description: 'Append a note to persistent memory',
          parameters: [
            ToolParameter(
                name: 'target', type: 'string', description: 'user or agent'),
            ToolParameter(
                name: 'content', type: 'string', description: 'Content to add'),
          ],
          onExecute: (a) async {
            if (a['target'] == 'user') {
              await memory.appendUserProfile('${a['content']}');
            } else {
              await memory.appendAgentMemory('${a['content']}');
            }
            return 'OK';
          },
        ),
        Tool(
          name: 'skills_list',
          description: 'List available skills',
          onExecute: (a) async =>
              skills.skills.map((s) => '- ${s.name}: ${s.description}').join('\n'),
        ),
        Tool(
          name: 'skills_view',
          description: 'View a specific skill',
          parameters: [
            ToolParameter(name: 'name', type: 'string', description: 'Skill name'),
          ],
          onExecute: (a) async =>
              skills.getSkill('${a['name']}')?.content ?? 'Skill not found',
        ),
      ];
}
