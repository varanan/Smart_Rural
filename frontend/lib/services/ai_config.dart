import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/bus_timetable.dart';
import 'api_service.dart';
import 'ai_service.dart';

class AIConfig {
  // AI Service Configuration
  static const bool enableAI = true;
  static const int responseTimeoutSeconds = 10;
  static const int maxResponseLength = 300;

  // Hugging Face Configuration (Free - No API Key Required)
  static const String huggingFaceBaseUrl =
      'https://api-inference.huggingface.co/models';
  static const List<String> huggingFaceModels = [
    'microsoft/DialoGPT-medium',
    'facebook/blenderbot-400M-distill',
    'microsoft/DialoGPT-small',
  ];

  // Cohere Configuration (Free Tier Available)
  static const String cohereApiUrl = 'https://api.cohere.ai/v1/generate';
  static const String cohereApiKey = ''; // Add your free API key here

  // Ollama Configuration (Local AI - Completely Free)
  static const String ollamaBaseUrl = 'http://localhost:11434';
  static const List<String> ollamaModels = ['llama2', 'codellama', 'mistral'];

  // OpenAI-Compatible APIs (Many free alternatives available)
  static const List<Map<String, String>> freeOpenAICompatibleAPIs = [
    {
      'name': 'Together AI',
      'baseUrl': 'https://api.together.xyz/v1',
      'model': 'meta-llama/Llama-2-7b-chat-hf',
      'apiKey': '', // Free tier available
    },
    {
      'name': 'Groq',
      'baseUrl': 'https://api.groq.com/openai/v1',
      'model': 'llama2-70b-4096',
      'apiKey': '', // Free tier available
    },
  ];

  // Response Templates
  static const Map<String, List<String>> responseTemplates = {
    'greeting': [
      'Hello! I\'m your AI assistant for Smart Rural Transportation. How can I help you today?',
      'Hi there! I\'m here to help with bus schedules and transportation questions.',
      'Welcome! I\'m your intelligent travel assistant. What do you need to know?',
    ],
    'busQuery': [
      'Let me help you find the best bus options for your journey.',
      'I\'ll search for available buses on that route.',
      'Checking bus schedules for you right now...',
    ],
    'error': [
      'I apologize, but I\'m having trouble processing that request right now.',
      'Something went wrong on my end. Could you please try again?',
      'I encountered an issue. Let me try a different approach.',
    ],
  };

  // Context for AI responses
  static const String systemPrompt = '''
You are a helpful AI assistant for Smart Rural Transportation, a bus scheduling app in Sri Lanka.

Your primary functions:
1. Help users find bus schedules and routes
2. Provide transportation information
3. Answer general questions about travel in Sri Lanka
4. Be friendly, concise, and helpful

Guidelines:
- Keep responses under 200 words
- Be specific about bus routes when possible
- Suggest using the app's search features for detailed schedules
- If you don't know something, admit it and suggest alternatives
- Use emojis sparingly but appropriately (🚌 📍 🕐)

Available cities: Colombo, Kandy, Galle, Matara, Negombo, Anuradhapura, Polonnaruwa, Ratnapura, Badulla, Trincomalee, Jaffna, Kurunegala, Puttalam, Kalutara, Hambantota.
''';
}
