import 'dart:convert';
import 'dart:math';
import '../models/chat_message.dart';
import '../models/bus_timetable.dart';
import 'api_service.dart';

class ChatbotService {
  static final List<String> _greetings = [
    'Hello! I\'m your Smart Rural Transportation assistant. How can I help you today?',
    'Hi there! I\'m here to help you with bus schedules and transportation info. What do you need?',
    'Welcome! I can help you find bus routes, schedules, and answer transportation questions. How may I assist you?',
  ];

  static final List<String> _busRelatedKeywords = [
    'bus',
    'schedule',
    'timetable',
    'route',
    'departure',
    'arrival',
    'from',
    'to',
    'time',
    'when',
    'where',
    'how',
    'travel',
    'trip',
    'express',
    'luxury',
    'normal',
    'intercity',
    'semi-luxury',
  ];

  static final Map<String, List<String>> _quickResponses = {
    'greeting': [
      'Hello! How can I help you with your travel plans?',
      'Hi! I\'m here to assist with bus schedules and routes.',
      'Welcome! What transportation information do you need?',
    ],
    'thanks': [
      'You\'re welcome! Have a safe journey!',
      'Happy to help! Safe travels!',
      'Glad I could assist! Enjoy your trip!',
    ],
    'goodbye': [
      'Goodbye! Have a great day and safe travels!',
      'See you later! Don\'t hesitate to ask if you need more help.',
      'Take care! Have a wonderful journey!',
    ],
    'help': [
      'I can help you with:\n• Finding bus schedules\n• Route information\n• Departure and arrival times\n• Bus types (Express, Luxury, etc.)\n\nJust ask me something like "Show me buses from Colombo to Kandy"',
      'Here\'s what I can do:\n• Search bus timetables\n• Provide route details\n• Help with travel planning\n• Answer transportation questions\n\nTry asking "What buses go from [city] to [city]?"',
    ],
  };

  static final List<String> _locations = [
    'Colombo',
    'Kandy',
    'Galle',
    'Matara',
    'Negombo',
    'Anuradhapura',
    'Polonnaruwa',
    'Ratnapura',
    'Badulla',
    'Trincomalee',
    'Jaffna',
    'Kurunegala',
    'Puttalam',
    'Kalutara',
    'Hambantota',
  ];

  static Future<ChatMessage> processMessage(String userMessage) async {
    final messageId = _generateId();
    final timestamp = DateTime.now();

    try {
      // Normalize the message
      final normalizedMessage = userMessage.toLowerCase().trim();

      // Check for greetings
      if (_isGreeting(normalizedMessage)) {
        return ChatMessage(
          id: messageId,
          content: _getRandomResponse(_quickResponses['greeting']!),
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.text,
        );
      }

      // Check for thanks
      if (_isThanks(normalizedMessage)) {
        return ChatMessage(
          id: messageId,
          content: _getRandomResponse(_quickResponses['thanks']!),
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.text,
        );
      }

      // Check for goodbye
      if (_isGoodbye(normalizedMessage)) {
        return ChatMessage(
          id: messageId,
          content: _getRandomResponse(_quickResponses['goodbye']!),
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.text,
        );
      }

      // Check for help request
      if (_isHelpRequest(normalizedMessage)) {
        return ChatMessage(
          id: messageId,
          content: _getRandomResponse(_quickResponses['help']!),
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.text,
        );
      }

      // Check if it's a bus-related query
      if (_isBusRelated(normalizedMessage)) {
        return await _handleBusQuery(userMessage, messageId, timestamp);
      }

      // Default response for unrecognized queries
      return ChatMessage(
        id: messageId,
        content:
            'I\'m specialized in helping with bus schedules and transportation. Try asking me about:\n• Bus routes between cities\n• Departure times\n• Bus types\n\nFor example: "Show me buses from Colombo to Kandy"',
        isUser: false,
        timestamp: timestamp,
        type: ChatMessageType.text,
      );
    } catch (e) {
      return ChatMessage(
        id: messageId,
        content:
            'Sorry, I encountered an error while processing your request. Please try again.',
        isUser: false,
        timestamp: timestamp,
        type: ChatMessageType.error,
      );
    }
  }

  static Future<ChatMessage> _handleBusQuery(
    String userMessage,
    String messageId,
    DateTime timestamp,
  ) async {
    try {
      // Extract locations from the message
      final extractedInfo = _extractBusInfo(userMessage);

      // Search for bus schedules
      final response = await ApiService.getBusTimeTable(
        from: extractedInfo['from'],
        to: extractedInfo['to'],
        startTime: extractedInfo['time'],
        busType: extractedInfo['busType'],
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        final timetables = data
            .map((json) => BusTimeTable.fromJson(json))
            .toList();

        if (timetables.isEmpty) {
          return ChatMessage(
            id: messageId,
            content: _generateNoResultsMessage(extractedInfo),
            isUser: false,
            timestamp: timestamp,
            type: ChatMessageType.text,
          );
        }

        return ChatMessage(
          id: messageId,
          content: _generateBusScheduleMessage(timetables, extractedInfo),
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.busSchedule,
          metadata: {
            'timetables': timetables.map((t) => t.toJson()).toList(),
            'searchCriteria': extractedInfo,
          },
        );
      } else {
        return ChatMessage(
          id: messageId,
          content:
              'I couldn\'t find any bus schedules at the moment. Please try again later or check if the route exists.',
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.text,
        );
      }
    } catch (e) {
      return ChatMessage(
        id: messageId,
        content:
            'I\'m having trouble accessing the bus schedule database. Please try again in a moment.',
        isUser: false,
        timestamp: timestamp,
        type: ChatMessageType.error,
      );
    }
  }

  static Map<String, String?> _extractBusInfo(String message) {
    final normalizedMessage = message.toLowerCase();
    String? from, to, time, busType;

    // Extract locations
    for (final location in _locations) {
      final locationLower = location.toLowerCase();
      if (normalizedMessage.contains(locationLower)) {
        if (from == null) {
          from = location;
        } else if (to == null && location != from) {
          to = location;
        }
      }
    }

    // Look for "from X to Y" pattern
    final fromToPattern = RegExp(
      r'from\s+(\w+)\s+to\s+(\w+)',
      caseSensitive: false,
    );
    final fromToMatch = fromToPattern.firstMatch(normalizedMessage);
    if (fromToMatch != null) {
      final fromCandidate = _findClosestLocation(fromToMatch.group(1)!);
      final toCandidate = _findClosestLocation(fromToMatch.group(2)!);
      if (fromCandidate != null) from = fromCandidate;
      if (toCandidate != null) to = toCandidate;
    }

    // Extract time
    final timePattern = RegExp(
      r'(\d{1,2}):?(\d{2})?\s*(am|pm)?',
      caseSensitive: false,
    );
    final timeMatch = timePattern.firstMatch(normalizedMessage);
    if (timeMatch != null) {
      time = timeMatch.group(0);
    }

    // Extract bus type
    for (final type in BusType.values) {
      if (normalizedMessage.contains(type.displayName.toLowerCase())) {
        busType = type.displayName;
        break;
      }
    }

    return {'from': from, 'to': to, 'time': time, 'busType': busType};
  }

  static String? _findClosestLocation(String input) {
    final inputLower = input.toLowerCase();
    return _locations.firstWhere(
      (location) => location.toLowerCase().startsWith(inputLower),
      orElse: () => _locations.firstWhere(
        (location) => location.toLowerCase().contains(inputLower),
        orElse: () => '',
      ),
    );
  }

  static String _generateBusScheduleMessage(
    List<BusTimeTable> timetables,
    Map<String, String?> searchInfo,
  ) {
    final buffer = StringBuffer();

    if (searchInfo['from'] != null && searchInfo['to'] != null) {
      buffer.writeln(
        '🚌 Found ${timetables.length} bus(es) from ${searchInfo['from']} to ${searchInfo['to']}:\n',
      );
    } else {
      buffer.writeln('🚌 Found ${timetables.length} bus schedule(s):\n');
    }

    for (int i = 0; i < timetables.length && i < 5; i++) {
      final bus = timetables[i];
      buffer.writeln('${i + 1}. ${bus.busType} Bus');
      buffer.writeln('   📍 ${bus.from} → ${bus.to}');
      buffer.writeln('   🕐 ${bus.startTime} - ${bus.endTime}');
      if (i < timetables.length - 1 && i < 4) buffer.writeln();
    }

    if (timetables.length > 5) {
      buffer.writeln(
        '\n... and ${timetables.length - 5} more buses available.',
      );
    }

    buffer.writeln(
      '\n💡 Tip: You can ask me for more specific details or different routes!',
    );

    return buffer.toString();
  }

  static String _generateNoResultsMessage(Map<String, String?> searchInfo) {
    final buffer = StringBuffer();
    buffer.writeln('😔 No buses found');

    if (searchInfo['from'] != null && searchInfo['to'] != null) {
      buffer.writeln(
        'for the route ${searchInfo['from']} to ${searchInfo['to']}.',
      );
    } else if (searchInfo['from'] != null) {
      buffer.writeln('departing from ${searchInfo['from']}.');
    } else if (searchInfo['to'] != null) {
      buffer.writeln('going to ${searchInfo['to']}.');
    } else {
      buffer.writeln('matching your criteria.');
    }

    buffer.writeln('\n💡 Try:');
    buffer.writeln('• Different cities or times');
    buffer.writeln('• "Show all buses" for complete schedule');
    buffer.writeln('• Asking about popular routes like "Colombo to Kandy"');

    return buffer.toString();
  }

  static bool _isGreeting(String message) {
    final greetingWords = [
      'hello',
      'hi',
      'hey',
      'good morning',
      'good afternoon',
      'good evening',
    ];
    return greetingWords.any((greeting) => message.contains(greeting));
  }

  static bool _isThanks(String message) {
    final thanksWords = ['thank', 'thanks', 'appreciate', 'grateful'];
    return thanksWords.any((thanks) => message.contains(thanks));
  }

  static bool _isGoodbye(String message) {
    final goodbyeWords = [
      'bye',
      'goodbye',
      'see you',
      'farewell',
      'exit',
      'quit',
    ];
    return goodbyeWords.any((goodbye) => message.contains(goodbye));
  }

  static bool _isHelpRequest(String message) {
    final helpWords = [
      'help',
      'assist',
      'support',
      'what can you do',
      'how to',
      'guide',
    ];
    return helpWords.any((help) => message.contains(help));
  }

  static bool _isBusRelated(String message) {
    return _busRelatedKeywords.any((keyword) => message.contains(keyword));
  }

  static String _getRandomResponse(List<String> responses) {
    final random = Random();
    return responses[random.nextInt(responses.length)];
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static ChatMessage getWelcomeMessage() {
    return ChatMessage(
      id: _generateId(),
      content: _getRandomResponse(_greetings),
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );
  }

  static List<String> getQuickReplies() {
    return [
      'Show all buses',
      'Buses from Colombo',
      'Express buses',
      'Help me plan a trip',
      'What can you do?',
    ];
  }
}
