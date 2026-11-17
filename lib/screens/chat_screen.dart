import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/llm_service.dart';
import '../services/storage.dart';
import '../services/skill_manager.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isProcessing = false;
  String _streamingContent = '';

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isProcessing) return;

    final llm = context.read<LLMService>();
    final sessionManager = context.read<SessionManager>();
    final memoryStore = context.read<MemoryStore>();
    final skillManager = context.read<SkillManager>();

    setState(() {
      _isProcessing = true;
      _streamingContent = '';
    });

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );
    sessionManager.addMessage(userMessage);

    // Build context
    final contextMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt(memoryStore, skillManager),
      },
    ];

    for (final msg in sessionManager.currentSession?.messages ?? []) {
      if (msg.role != MessageRole.system) {
        contextMessages.add(msg.toOpenAiFormat());
      }
    }

    // Stream response
    try {
      final stream = llm.streamChat(contextMessages, null);
      await for (final chunk in stream) {
        if (mounted) {
          setState(() => _streamingContent += chunk);
        }
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
          );
        }
      }

      if (_streamingContent.isNotEmpty) {
        sessionManager.addMessage(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          content: _streamingContent,
          timestamp: DateTime.now(),
        ));
        await sessionManager.saveCurrentSession();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _streamingContent = '';
        });
        _inputController.clear();
      }
    }
  }

  String _buildSystemPrompt(MemoryStore memory, SkillManager skills) {
    final buffer = StringBuffer();
    buffer.writeln('You are Hermes, a capable AI assistant.');
    buffer.writeln('');
    buffer.writeln('## Core Principles');
    buffer.writeln('- Be direct and concise.');
    buffer.writeln('- Use tools when needed.');
    buffer.writeln('- No filler text.');
    buffer.writeln('- When unsure, say so plainly.');
    buffer.writeln('');

    if (memory.userProfile.isNotEmpty) {
      buffer.writeln('## User Profile');
      buffer.writeln(memory.userProfile);
      buffer.writeln('');
    }

    if (memory.agentMemory.isNotEmpty) {
      buffer.writeln('## Agent Memory');
      buffer.writeln(memory.agentMemory);
      buffer.writeln('');
    }

    if (skills.skills.isNotEmpty) {
      buffer.writeln('## Available Skills');
      for (final s in skills.skills) {
        buffer.writeln('- ${s.name}: ${s.description}');
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.title ?? 'Hermes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Chat',
            onPressed: () => sessionManager.createSession(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Clear this conversation?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        sessionManager.clearCurrentSession();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: session == null || session.messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: session.messages.length +
                        (_streamingContent.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < session.messages.length) {
                        return _buildMessage(
                            context, session.messages[index]);
                      }
                      return _buildStreamingBubble(context);
                    },
                  ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined,
              size: 72, color: theme.colorScheme.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a message below to begin',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, ChatMessage msg) {
    final theme = Theme.of(context);
    final isUser = msg.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.psychology,
                  size: 14,
                  color: isUser
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceContainerHighest,
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'You' : 'Hermes',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUser
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceContainerHighest,
                  ),
                ),
              ],
            ),
            const SizedBox(vertical: 3),
            MarkdownBody(
              data: msg.content,
              selectable: false,
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceContainerHighest,
                ),
                code: theme.textTheme.bodySmall?.copyWith(
                  backgroundColor: theme.colorScheme.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingBubble(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology,
                size: 14, color: theme.colorScheme.onSurfaceContainerHighest),
            const SizedBox(width: 6),
            Text('Hermes',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceContainerHighest,
                )),
            const SizedBox(width: 8),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _isProcessing ? null : _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isProcessing
                  ? null
                  : () => _sendMessage(_inputController.text),
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}