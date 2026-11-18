import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/skill_manager.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  String _search = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = context.watch<SkillManager>();

    var skills = manager.skills;
    if (_category != null) {
      skills = skills.where((s) => s.category == _category).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      skills = skills
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q))
          .toList();
    }

    final categories = manager.getCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => manager.init(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search skills...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          if (categories.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  ...categories.map((c) => FilterChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (sel) =>
                            setState(() => _category = sel ? c : null),
                      )),
                ],
              ),
            ),
          Expanded(
            child: skills.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.extension_outlined,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text('No skills found',
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5))),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: skills.length,
                    itemBuilder: (context, index) {
                      final s = skills[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        child: ExpansionTile(
                          leading: Icon(_icon(s.category),
                              color: theme.colorScheme.primary),
                          title: Text(s.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(children: [
                                Chip(
                                  label: Text(s.category),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 4),
                                Chip(
                                  label: Text('v${s.version}'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ]),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Content',
                                      style: theme.textTheme.titleSmall),
                                  const SizedBox(height: 8),
                                  SelectableText(s.content,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontFamily: 'monospace')),
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

  IconData _icon(String cat) {
    switch (cat.toLowerCase()) {
      case 'research': return Icons.search;
      case 'coding': return Icons.code;
      case 'general': return Icons.psychology;
      default: return Icons.extension;
    }
  }
}