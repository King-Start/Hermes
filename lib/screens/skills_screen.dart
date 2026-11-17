import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/skill_manager.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skillManager = context.watch<SkillManager>();

    var skills = skillManager.skills;

    // Filter by category
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      skills = skills.where((s) => s.category == _selectedCategory).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      skills = skills
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    final categories = skillManager.getCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              skillManager.init();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search skills...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category filter
          if (categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? null : null;
                      });
                    },
                  ),
                  ...categories.map(
                    (category) => FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Skills list
          Expanded(
            child: skills.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.extension,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No skills found',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: skills.length,
                    itemBuilder: (context, index) {
                      final skill = skills[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ExpansionTile(
                          leading: Icon(
                            _getCategoryIcon(skill.category),
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(skill.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skill.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(skill.category),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 4),
                                  Chip(
                                    label: Text('v${skill.version}'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Content',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    skill.content,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  if (skill.tools.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tools',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: skill.tools
                                          .map((tool) => Chip(label: Text(tool)))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'research':
        return Icons.search;
      case 'coding':
        return Icons.code;
      case 'general':
        return Icons.psychology;
      default:
        return Icons.extension;
    }
  }
}