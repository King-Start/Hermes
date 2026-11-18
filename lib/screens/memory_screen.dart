import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _userCtrl = TextEditingController();
  final _agentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  void _load() {
    final m = context.read<MemoryStore>();
    _userCtrl.text = m.userProfile;
    _agentCtrl.text = m.agentMemory;
  }

  Future<void> _saveUser() async {
    await context.read<MemoryStore>().setUserProfile(_userCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile saved')),
      );
    }
  }

  Future<void> _saveAgent() async {
    await context.read<MemoryStore>().setAgentMemory(_agentCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent memory saved')),
      );
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _userCtrl.dispose();
    _agentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'User Profile'),
            Tab(text: 'Agent Memory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildTab(
            context,
            icon: Icons.person,
            title: 'User Profile',
            description: 'Information about you that the agent should remember.',
            controller: _userCtrl,
            onSave: _saveUser,
          ),
          _buildTab(
            context,
            icon: Icons.psychology,
            title: 'Agent Memory',
            description: 'Notes and context the agent should remember.',
            controller: _agentCtrl,
            onSave: _saveAgent,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(description,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: title == 'User Profile'
                    ? 'Tell me about yourself...'
                    : 'Add notes for the agent...',
                filled: true,
                border: const OutlineInputBorder(),
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  controller.clear();
                  onSave();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}