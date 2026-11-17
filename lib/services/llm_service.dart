import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class LLMService extends ChangeNotifier {
  String baseUrl;
  String apiKey;
  String model;
  double temperature;
  int maxTokens;

  LLMService({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.temperature = 0.3,
    this.maxTokens = 8192,
  });

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  void updateConfig({
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
  }) {
    this.baseUrl = baseUrl ?? this.baseUrl;
    this.apiKey = apiKey ?? this.apiKey;
    this.model = model ?? this.model;
    this.temperature = temperature ?? this.temperature;
    this.maxTokens = maxTokens ?? this.maxTokens;
    notifyListeners();
  }

  /// Stream chat response. Yields text chunks.
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
        ..headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        }
        ..body = jsonEncode(body);

      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        yield '**Error ${streamedResponse.statusCode}:** $errorBody';
        return;
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

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
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          }
        } catch (_) {
          // Skip malformed chunks
        }
      }
    } catch (e) {
      yield '**Error:** ${e.toString()}';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Non-streaming chat. Returns full response with optional tool calls.
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
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}

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