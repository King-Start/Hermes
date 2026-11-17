import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/storage.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = context.watch<SessionManager>();
    final sessions = manager.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Session',
            onPressed: () {
              manager.createSession();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No sessions yet',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            )
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final s = sessions[index];
                final active = manager.currentSession?.id == s.id;
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 3),
                  color: active ? theme.colorScheme.primaryContainer : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Text(
                        s.title.isNotEmpty ? s.title[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: active
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceContainerHighest,
                        ),
                      ),
                    ),
                    title: Text(s.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        '${s.messages.length} msgs • ${_fmt(s.updatedAt)}'),
                    trailing: active
                        ? Icon(Icons.check_circle,
                            color: theme.colorScheme.primary)
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, s),
                          ),
                    onTap: () {
                      manager.loadSession(s.id);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, Session s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Delete "${s.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<SessionManager>().deleteSession(s.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) {
      return 'Today ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${d.day}/${d.month}/${d.year}';
  }
}