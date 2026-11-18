import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/chat.dart';

/// LLM Service - OpenAI-compatible API client
class LLMService extends ChangeNotifier {
  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;

  LLMService({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.temperature = 0.3,
    this.maxTokens = 8192,
  });

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  /// Chat completion with streaming
  Stream<String> streamChat(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  ) async* {
    _isBusy = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$baseUrl/chat/completions');
      final body = <String, dynamic>{
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        if (tools != null && tools.isNotEmpty) ...{
          'tools': tools,
          'tool_choice': 'auto',
        },
        'stream': true,
      };

      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        })
        ..body = jsonEncode(body);

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        yield '**Error:** HTTP ${response.statusCode} - $errorBody';
        return;
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String fullContent = ''; // ignore: unused_local_variable

      await for (final line in stream) {
        if (line.isEmpty) continue;
        if (!line.startsWith('data: ')) continue;

        final data = line.substring(6).trim();
        if (data == '[DONE]') break;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            if (delta != null) {
              final content = delta['content'] as String?;
              if (content != null) {
                fullContent += content;
                yield content;
              }

              // Handle tool calls in streaming
              final toolCalls = delta['tool_calls'] as List?;
              if (toolCalls != null && toolCalls.isNotEmpty) {
                // Tool calls will be handled by the agent
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing stream chunk: $e');
        }
      }
    } catch (e) {
      yield '**Error:** ${e.toString()}';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Non-streaming chat completion
  Future<ChatResponse> chat(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  ) async {
    _isBusy = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$baseUrl/chat/completions');
      final body = <String, dynamic>{
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        if (tools != null && tools.isNotEmpty) ...{
          'tools': tools,
          'tool_choice': 'auto',
        },
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List;
      final message = choices[0]['message'] as Map<String, dynamic>;

      return ChatResponse(
        content: message['content'] as String?,
        toolCalls: message['tool_calls'] != null
            ? (message['tool_calls'] as List)
                .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
                .toList()
            : null,
        finishReason: choices[0]['finish_reason'] as String? ?? 'stop',
      );
    } catch (e) {
      throw Exception('Chat error: $e');
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Count tokens (approximate)
  int countTokens(List<Map<String, dynamic>> messages) {
    int total = 0;
    for (final msg in messages) {
      final content = msg['content'] as String? ?? '';
      total += (content.length / 4).ceil(); // Rough estimate
    }
    return total;
  }
}

/// Chat response model
class ChatResponse {
  final String? content;
  final List<ToolCall>? toolCalls;
  final String finishReason;

  const ChatResponse({
    this.content,
    this.toolCalls,
    this.finishReason = 'stop',
  });
}