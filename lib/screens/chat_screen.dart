import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../models/chat.dart';
import '../../services/llm_service.dart';
import '../../services/session_manager.dart';
import '../../services/memory_store.dart';
import '../../services/skill_manager.dart';
import '../../core/config.dart';

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

    final config = context.read<ConfigManager>().config; // ignore: unused_local_variable
    final sessionManager = context.read<SessionManager>();
    final llmService = context.read<LLMService>();
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

    // Build context messages
    final contextMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _buildSystemPrompt(memoryStore, skillManager)},
    ];

    for (final msg in sessionManager.currentSession?.messages ?? []) {
      if (msg.role != MessageRole.system) {
        contextMessages.add(msg.toOpenAiFormat());
      }
    }

    // Stream response
    try {
      final stream = llmService.streamChat(contextMessages, null);

      await for (final chunk in stream) {
        setState(() {
          _streamingContent += chunk;
        });

        // Scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }

      // Add assistant message
      final assistantMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: _streamingContent,
        timestamp: DateTime.now(),
        isStreaming: false,
      );
      sessionManager.addMessage(assistantMessage);

      // Save session
      await sessionManager.saveCurrentSession();
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
    buffer.writeln('You are Hermes, a capable AI assistant with access to powerful tools.');
    buffer.writeln('');
    buffer.writeln('## Core Principles');
    buffer.writeln('- Be direct and concise.');
    buffer.writeln('- Use tools when needed; do not speculate when you can act.');
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
      for (final skill in skills.skills) {
        buffer.writeln('- ${skill.name}: ${skill.description}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  void _scrollToBottom() { // ignore: unused_element
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionManager = context.watch<SessionManager>();
    final currentSession = sessionManager.currentSession;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(currentSession?.title ?? 'New Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Chat',
            onPressed: () {
              sessionManager.createSession();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Chat',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Are you sure you want to clear this conversation?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        sessionManager.clearCurrentSession();
                        Navigator.pop(context);
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
            child: currentSession == null || currentSession.messages.isEmpty
                ? const EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: currentSession.messages.length +
                        (_streamingContent.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < currentSession.messages.length) {
                        final message = currentSession.messages[index];
                        return _buildMessage(context, message);
                      } else {
                        // Streaming message
                        return _buildStreamingMessage(context);
                      }
                    },
                  ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, ChatMessage message) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
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
                  size: 16,
                  color: isUser
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  isUser ? 'You' : 'Hermes',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUser
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            MarkdownBody(
              data: message.content,
              selectable: false,
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology,
              size: 16,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'Hermes',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurface,
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
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
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
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a message below to begin',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}