import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/bus_timetable.dart';
import 'api_service.dart';
import 'ai_config.dart';

class AIService {
  static final Random _random = Random();

  // Main AI response method that tries multiple free services
  static Future<String?> getAIResponse(String userMessage) async {
    if (!AIConfig.enableAI) {
      return null;
    }

    final List<Future<String?>> aiAttempts = [
      _tryHuggingFace(userMessage),
      _tryCohere(userMessage),
      _tryOllama(userMessage),
      _tryFreeOpenAICompatible(userMessage),
    ];

    // Try all services in parallel and return the first successful response
    for (final attempt in aiAttempts) {
      try {
        final response = await attempt.timeout(
          Duration(seconds: AIConfig.responseTimeoutSeconds),
        );
        if (response != null && response.trim().isNotEmpty) {
          return _cleanResponse(response);
        }
      } catch (e) {
        continue; // Try next service
      }
    }

    return null; // All services failed
  }

  // Hugging Face Inference API (Completely Free)
  static Future<String?> _tryHuggingFace(String message) async {
    try {
      final model =
          AIConfig.huggingFaceModels[_random.nextInt(
            AIConfig.huggingFaceModels.length,
          )];

      final response = await http.post(
        Uri.parse('${AIConfig.huggingFaceBaseUrl}/$model'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inputs': _buildPrompt(message),
          'parameters': {
            'max_length': 150,
            'temperature': 0.7,
            'do_sample': true,
            'top_p': 0.9,
            'repetition_penalty': 1.1,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['generated_text'];
        }
      }
    } catch (e) {
      print('Hugging Face error: $e');
    }
    return null;
  }

  // Cohere API (Free Tier Available)
  static Future<String?> _tryCohere(String message) async {
    if (AIConfig.cohereApiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse(AIConfig.cohereApiUrl),
        headers: {
          'Authorization': 'Bearer ${AIConfig.cohereApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'command-light',
          'prompt': _buildPrompt(message),
          'max_tokens': 100,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['generations'][0]['text'];
      }
    } catch (e) {
      print('Cohere error: $e');
    }
    return null;
  }

  // Ollama Local AI (Completely Free)
  static Future<String?> _tryOllama(String message) async {
    try {
      final model = AIConfig.ollamaModels[0]; // Use first available model

      final response = await http.post(
        Uri.parse('${AIConfig.ollamaBaseUrl}/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'prompt': _buildPrompt(message),
          'stream': false,
          'options': {'temperature': 0.7, 'top_p': 0.9},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      }
    } catch (e) {
      print('Ollama error: $e');
    }
    return null;
  }

  // Free OpenAI-Compatible APIs
  static Future<String?> _tryFreeOpenAICompatible(String message) async {
    for (final api in AIConfig.freeOpenAICompatibleAPIs) {
      if (api['apiKey']?.isEmpty ?? true) continue;

      try {
        final response = await http.post(
          Uri.parse('${api['baseUrl']}/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${api['apiKey']}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': api['model'],
            'messages': [
              {'role': 'system', 'content': AIConfig.systemPrompt},
              {'role': 'user', 'content': message},
            ],
            'max_tokens': 150,
            'temperature': 0.7,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        }
      } catch (e) {
        print('${api['name']} error: $e');
        continue;
      }
    }
    return null;
  }

  // Build contextual prompt
  static String _buildPrompt(String userMessage) {
    return '''${AIConfig.systemPrompt}

User: $userMessage
Assistant:''';
  }

  // Clean and format AI response
  static String _cleanResponse(String response) {
    String cleaned = response.trim();

    // Remove common AI artifacts
    cleaned = cleaned.replaceAll(
      RegExp(
        r'^(Assistant:|AI:|Bot:|User:.*?Assistant:)\s*',
        caseSensitive: false,
        multiLine: true,
      ),
      '',
    );

    // Remove repetitive patterns
    cleaned = cleaned.replaceAll(RegExp(r'(.{10,}?)\1+'), r'$1');

    // Limit length
    if (cleaned.length > AIConfig.maxResponseLength) {
      cleaned = cleaned.substring(0, AIConfig.maxResponseLength);
      // Try to end at a sentence
      final lastSentence = cleaned.lastIndexOf('.');
      if (lastSentence > AIConfig.maxResponseLength * 0.7) {
        cleaned = cleaned.substring(0, lastSentence + 1);
      } else {
        cleaned += '...';
      }
    }

    return cleaned.trim();
  }

  // Check if AI services are available
  static Future<Map<String, bool>> checkServiceAvailability() async {
    final results = <String, bool>{};

    // Check Hugging Face
    try {
      final response = await http
          .get(
            Uri.parse(
              '${AIConfig.huggingFaceBaseUrl}/${AIConfig.huggingFaceModels[0]}',
            ),
          )
          .timeout(const Duration(seconds: 5));
      results['HuggingFace'] = response.statusCode == 200;
    } catch (e) {
      results['HuggingFace'] = false;
    }

    // Check Ollama
    try {
      final response = await http
          .get(Uri.parse('${AIConfig.ollamaBaseUrl}/api/tags'))
          .timeout(const Duration(seconds: 5));
      results['Ollama'] = response.statusCode == 200;
    } catch (e) {
      results['Ollama'] = false;
    }

    // Check Cohere
    results['Cohere'] = AIConfig.cohereApiKey.isNotEmpty;

    return results;
  }
}
