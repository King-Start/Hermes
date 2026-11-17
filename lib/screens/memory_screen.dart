import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/memory_store.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _userController = TextEditingController();
  final _agentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMemory();
  }

  void _loadMemory() {
    final memory = context.read<MemoryStore>();
    _userController.text = memory.userProfile;
    _agentController.text = memory.agentMemory;
  }

  Future<void> _saveUserProfile() async {
    await context.read<MemoryStore>().setUserProfile(_userController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile saved')),
      );
    }
  }

  Future<void> _saveAgentMemory() async {
    await context.read<MemoryStore>().setAgentMemory(_agentController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent memory saved')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userController.dispose();
    _agentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memory = context.watch<MemoryStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'User Profile'),
            Tab(text: 'Agent Memory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // User Profile Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'User Profile',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Information about you that the agent should remember across sessions.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      hintText: 'Tell me about yourself...',
                      border: OutlineInputBorder(),
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
                        _userController.clear();
                        _saveUserProfile();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saveUserProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Agent Memory Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Agent Memory',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Notes and context the agent should remember for better responses.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _agentController,
                    decoration: const InputDecoration(
                      hintText: 'Add notes or context for the agent...',
                      border: OutlineInputBorder(),
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
                        _agentController.clear();
                        _saveAgentMemory();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saveAgentMemory,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}