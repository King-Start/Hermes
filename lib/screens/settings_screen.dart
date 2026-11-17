import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final c = context.read<ConfigManager>().config;
    _baseUrlCtrl.text = c.baseUrl;
    _apiKeyCtrl.text = c.apiKey;
    _modelCtrl.text = c.model;
  }

  Future<void> _save() async {
    final manager = context.read<ConfigManager>();
    final c = manager.config;
    await manager.updateConfig(c.copyWith(
      baseUrl: _baseUrlCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = context.watch<ConfigManager>().config;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // LLM Config
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.psychology, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('LLM Configuration',
                        style: theme.textTheme.titleMedium),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _baseUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://api.openai.com/v1',
                      helperText: 'OpenAI-compatible endpoint',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyCtrl,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'sk-...',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'gpt-4o-mini',
                      helperText: 'Model identifier',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Text('Temperature: ${config.temperature.toStringAsFixed(2)}'),
                    Expanded(
                      child: Slider(
                        value: config.temperature,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        label: config.temperature.toStringAsFixed(2),
                        onChanged: (v) {
                          context.read<ConfigManager>().updateConfig(
                              config.copyWith(temperature: v));
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(vertical: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.tune, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Features', style: theme.textTheme.titleMedium),
                  ]),
                  SwitchListTile(
                    title: const Text('Enable Tools'),
                    subtitle: const Text('File, terminal, web search'),
                    value: config.enableTools,
                    onChanged: (v) => context.read<ConfigManager>().updateConfig(
                        config.copyWith(enableTools: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Skills'),
                    subtitle: const Text('Load reusable capabilities'),
                    value: config.enableSkills,
                    onChanged: (v) => context.read<ConfigManager>().updateConfig(
                        config.copyWith(enableSkills: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Memory'),
                    subtitle: const Text('Persistent context across sessions'),
                    value: config.enableMemory,
                    onChanged: (v) => context.read<ConfigManager>().updateConfig(
                        config.copyWith(enableMemory: v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('About', style: theme.textTheme.titleMedium),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Hermes Agent v1.0.0'),
                  const Text('AI assistant with tools, skills, and memory'),
                  const SizedBox(height: 8),
                  Text('Inspired by Hermes Agent',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}