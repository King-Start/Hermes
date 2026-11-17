import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    final config = context.read<ConfigManager>().config;
    _baseUrlController.text = config.baseUrl;
    _apiKeyController.text = config.apiKey;
    _modelController.text = config.model;
  }

  Future<void> _saveConfig() async {
    final configManager = context.read<ConfigManager>();
    final newConfig = configManager.config.copyWith(
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
    );
    await configManager.updateConfig(newConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = context.watch<ConfigManager>().config;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // LLM Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'LLM Settings',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://api.openai.com/v1',
                      helperText: 'OpenAI-compatible API endpoint',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'sk-...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureApiKey = !_obscureApiKey;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureApiKey,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'gpt-4o-mini',
                      helperText: 'Model name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Temperature: ${config.temperature.toStringAsFixed(2)}'),
                      Expanded(
                        child: Slider(
                          value: config.temperature,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: config.temperature.toStringAsFixed(2),
                          onChanged: (value) {
                            context.read<ConfigManager>().updateConfig(
                              config.copyWith(temperature: value),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saveConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Feature Toggles
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Features',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Tools'),
                    subtitle: const Text('Allow agent to use file/terminal/web tools'),
                    value: config.enableTools,
                    onChanged: (value) {
                      context.read<ConfigManager>().updateConfig(
                        config.copyWith(enableTools: value),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Enable Skills'),
                    subtitle: const Text('Load reusable skill capabilities'),
                    value: config.enableSkills,
                    onChanged: (value) {
                      context.read<ConfigManager>().updateConfig(
                        config.copyWith(enableSkills: value),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Enable Memory'),
                    subtitle: const Text('Persistent user profile & agent notes'),
                    value: config.enableMemory,
                    onChanged: (value) {
                      context.read<ConfigManager>().updateConfig(
                        config.copyWith(enableMemory: value),
                      );
                    },
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
                  Row(
                    children: [
                      Icon(Icons.info, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'About',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Hermes Agent v1.0.0'),
                  const Text('AI assistant with tools, skills, and memory'),
                  const SizedBox(height: 8),
                  Text(
                    'Inspired by Hermes Agent',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}