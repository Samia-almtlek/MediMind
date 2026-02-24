import 'dart:convert';

import 'package:http/http.dart' as http;

import 'chatbot_prompts.dart';

class LmStudioException implements Exception {
  final String message;

  LmStudioException(this.message);

  @override
  String toString() => message;
}

class LmStudioChatClient {
  LmStudioChatClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String> complete({
    required Uri endpoint,
    required String model,
    required String authorizedContext,
    String? extraContext,
    required String question,
  }) async {
    final response = await _httpClient.post(
      endpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'stream': false,
        'temperature': 0.1,
        'top_p': 0.9,
        'top_k': 40,
        'repeat_penalty': 1.1,
        'max_tokens': 512,
        'messages': [
          {
            'role': 'system',
            'content': kStrictSystemPrompt,
          },
          {
            'role': 'user',
            'content': buildBoundedUserPrompt(
              authorizedContext: authorizedContext,
              extraContext: extraContext,
              question: question,
            ),
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LmStudioException(
        'LM Studio request failed (${response.statusCode}).',
      );
    }

    final dynamic body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw LmStudioException('Invalid LM Studio response format.');
    }

    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      throw LmStudioException('LM Studio returned no choices.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      throw LmStudioException('Invalid LM Studio choice format.');
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw LmStudioException('LM Studio returned no message payload.');
    }

    final content = message['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content.trim();
    }

    throw LmStudioException('LM Studio returned an empty answer.');
  }

  void dispose() {
    _httpClient.close();
  }
}
