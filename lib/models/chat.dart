import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Role of a chat message
enum MessageRole {
  system,
  user,
  assistant,
  tool;

  String toJson() => name;
  static MessageRole fromJson(String value) =>
      MessageRole.values.firstWhere((e) => e.name == value);
}

/// A chat message
class ChatMessage extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final String? toolCallId;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final String? toolResult;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.toolCallId,
    this.toolName,
    this.toolArgs,
    this.toolResult,
    required this.timestamp,
    this.isStreaming = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      role: MessageRole.fromJson(map['role'] as String),
      content: map['content'] as String,
      toolCallId: map['toolCallId'] as String?,
      toolName: map['toolName'] as String?,
      toolArgs: map['toolArgs'] != null
          ? Map<String, dynamic>.from(map['toolArgs'] as Map)
          : null,
      toolResult: map['toolResult'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isStreaming: map['isStreaming'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role.toJson(),
      'content': content,
      if (toolCallId != null) 'toolCallId': toolCallId,
      if (toolName != null) 'toolName': toolName,
      if (toolArgs != null) 'toolArgs': toolArgs,
      if (toolResult != null) 'toolResult': toolResult,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isStreaming': isStreaming,
    };
  }

  /// Convert to OpenAI API format
  Map<String, dynamic> toOpenAiFormat() {
    final base = {'role': role.name, 'content': content};
    if (toolCallId != null) {
      base['tool_call_id'] = toolCallId;
    }
    if (toolName != null) {
      base['tool_calls'] = [
        {
          'id': toolCallId,
          'type': 'function',
          'function': {
            'name': toolName,
            'arguments': jsonEncode(toolArgs ?? {}),
          },
        },
      ];
    }
    return base;
  }

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    String? toolCallId,
    String? toolName,
    Map<String, dynamic>? toolArgs,
    String? toolResult,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      toolArgs: toolArgs ?? this.toolArgs,
      toolResult: toolResult ?? this.toolResult,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [id, role, content, toolCallId, toolName, toolArgs, toolResult, timestamp, isStreaming];
}

/// Tool call from LLM response
class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      name: json['function']['name'] as String,
      arguments: json['function']['arguments'] != null
          ? jsonDecode(json['function']['arguments'] as String) as Map<String, dynamic>
          : {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'function',
        'function': {
          'name': name,
          'arguments': jsonEncode(arguments),
        },
      };
}

/// Session for conversation history
class Session {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final Map<String, dynamic>? metadata;

  const Session({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.metadata,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'messages': messages.map((m) => m.toMap()).toList(),
        if (metadata != null) 'metadata': metadata,
      };

  Session copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    Map<String, dynamic>? metadata,
  }) {
    return Session(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      metadata: metadata ?? this.metadata,
    );
  }
}