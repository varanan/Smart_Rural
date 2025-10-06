import 'dart:convert';
import 'dart:math';
import '../models/chat_message.dart';
import '../models/bus_timetable.dart';
import '../models/review.dart';
import 'api_service.dart';
import 'ai_service.dart';

class ChatbotService {
  static final List<String> _greetings = [
    'Hello! I\'m your AI-powered Smart Rural Transportation assistant. How can I help you today?',
    'Hi there! I\'m an AI assistant here to help you with bus schedules and transportation info. What do you need?',
    'Welcome! I\'m your intelligent assistant for bus routes, schedules, and transportation questions. How may I assist you?',
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

  // ✅ ADD: Review-related keywords
  static final List<String> _reviewRelatedKeywords = [
    'review',
    'reviews',
    'rating',
    'ratings',
    'feedback',
    'comment',
    'comments',
    'opinion',
    'star',
    'stars',
    'rate',
    'rated',
  ];

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

  // Main message processing function with AI integration
  static Future<ChatMessage> processMessage(String userMessage) async {
    final messageId = _generateId();
    final timestamp = DateTime.now();

    try {
      final normalizedMessage = userMessage.toLowerCase().trim();

      // ✅ ADD: Check if it's a review-related query
      if (_isReviewRelated(normalizedMessage)) {
        return await _handleReviewQuery(userMessage, messageId, timestamp);
      }

      // Check if it's a bus-related query first
      if (_isBusRelated(normalizedMessage)) {
        return await _handleBusQuery(userMessage, messageId, timestamp);
      }

      // For general questions, use AI
      return await _getAIResponse(userMessage, messageId, timestamp);
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

  // AI Response Generation using the new AI service
  static Future<ChatMessage> _getAIResponse(
    String userMessage,
    String messageId,
    DateTime timestamp,
  ) async {
    try {
      // Try to get AI response
      String? aiResponse = await AIService.getAIResponse(userMessage);

      // If AI fails, use fallback
      if (aiResponse == null || aiResponse.trim().isEmpty) {
        aiResponse = _getFallbackResponse(userMessage);
      }

      return ChatMessage(
        id: messageId,
        content: aiResponse,
        isUser: false,
        timestamp: timestamp,
        type: ChatMessageType.text,
      );
    } catch (e) {
      return ChatMessage(
        id: messageId,
        content: _getFallbackResponse(userMessage),
        isUser: false,
        timestamp: timestamp,
        type: ChatMessageType.text,
      );
    }
  }

  // Fallback response system
  static String _getFallbackResponse(String message) {
    final normalizedMessage = message.toLowerCase();

    if (_isGreeting(normalizedMessage)) {
      return _getRandomResponse([
        'Hello! How can I help you with your travel plans today?',
        'Hi there! I\'m here to assist with bus schedules and routes.',
        'Welcome! What transportation information do you need?',
      ]);
    }

    if (_isThanks(normalizedMessage)) {
      return _getRandomResponse([
        'You\'re welcome! Have a safe journey!',
        'Happy to help! Safe travels!',
        'Glad I could assist! Enjoy your trip!',
      ]);
    }

    if (_isGoodbye(normalizedMessage)) {
      return _getRandomResponse([
        'Goodbye! Have a great day and safe travels!',
        'See you later! Don\'t hesitate to ask if you need more help.',
        'Take care! Have a wonderful journey!',
      ]);
    }

    // Default intelligent response
    return '''I'm here to help with transportation questions! I can assist you with:

🚌 Bus schedules and routes
🕐 Departure and arrival times  
📍 Travel planning between cities
⭐ Bus reviews and ratings
❓ General transportation questions

Try asking me something like:
• "Show me buses from Colombo to Kandy"
• "What time do express buses leave?"
• "How do I write a review?"
• "Show me reviews for buses"

What would you like to know?''';
  }

  // ✅ ADD: Review query handling
  static Future<ChatMessage> _handleReviewQuery(
    String userMessage,
    String messageId,
    DateTime timestamp,
  ) async {
    try {
      final normalizedMessage = userMessage.toLowerCase();

      // Check what kind of review query it is
      if (_isAboutWritingReview(normalizedMessage)) {
        return ChatMessage(
          id: messageId,
          content: '''📝 **How to Write a Review:**

1. Navigate to "My Reviews" from your dashboard
2. Or view bus schedules and click "Write Review" on a bus
3. Rate the bus (1-5 stars) ⭐
4. Write your comment (at least 10 characters)
5. Submit your review!

Your reviews help other passengers make better travel choices. 🚌

Would you like to see your existing reviews or browse bus schedules?''',
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.text,
        );
      }

      if (_isAboutViewingReviews(normalizedMessage)) {
        return ChatMessage(
          id: messageId,
          content: '''👀 **How to View Reviews:**

**Your Reviews:**
• Go to "My Reviews" from your dashboard
• See all buses you've reviewed
• Edit or delete your own reviews
• Click "View All Reviews" to see what others said

**All Reviews for a Bus:**
• Browse bus schedules
• Click "View All Reviews" on any bus
• See ratings and comments from all passengers
• Your reviews are highlighted with an orange border

You can view others' reviews but only edit/delete your own!''',
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.text,
        );
      }

      if (_isAboutEditingReview(normalizedMessage)) {
        return ChatMessage(
          id: messageId,
          content: '''✏️ **How to Edit Your Review:**

1. Go to "My Reviews" from your dashboard
2. Find the review you want to edit
3. Click the "Edit" button
4. Update your rating or comment
5. Save changes

Note: You can only edit your own reviews, not reviews from other passengers.''',
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.text,
        );
      }

      if (_isAboutDeletingReview(normalizedMessage)) {
        return ChatMessage(
          id: messageId,
          content: '''🗑️ **How to Delete Your Review:**

1. Go to "My Reviews" from your dashboard
2. Find the review you want to remove
3. Click the "Delete" button
4. Confirm deletion

Your review will be permanently removed. You can always write a new one later!''',
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.text,
        );
      }

      // Try to fetch recent reviews
      try {
        final reviews = await ApiService.getMyReviews();
        if (reviews.isNotEmpty) {
          return ChatMessage(
            id: messageId,
            content: '''⭐ **Your Reviews:**

You have ${reviews.length} review${reviews.length > 1 ? 's' : ''}.

To view, edit, or delete your reviews:
• Open "My Reviews" from your dashboard
• Click "View All Reviews" on any review to see what others said about that bus

Would you like me to help you with anything else about reviews?''',
            isUser: false,
            timestamp: timestamp,
            type: ChatMessageType.text,
          );
        } else {
          return ChatMessage(
            id: messageId,
            content: '''📝 You haven't written any reviews yet!

**How to get started:**
1. Browse bus schedules
2. Find a bus you've traveled on
3. Click "Write Review"
4. Share your experience!

Your feedback helps other passengers make informed decisions. 🚌''',
            isUser: false,
            timestamp: timestamp,
            type: ChatMessageType.text,
          );
        }
      } catch (e) {
        // If API call fails, provide general info
        return ChatMessage(
          id: messageId,
          content: '''⭐ **About Reviews:**

**Write a Review:**
• Browse bus schedules → Click "Write Review"
• Or go to "My Reviews" from dashboard

**View Reviews:**
• "My Reviews" - See your reviews
• "View All Reviews" on any bus - See all passenger reviews

**Edit/Delete:**
• Only possible for your own reviews
• Go to "My Reviews" → Click Edit or Delete

Need help with something specific about reviews?''',
          isUser: false,
          timestamp: timestamp,
          type: ChatMessageType.text,
        );
      }
    } catch (e) {
      return ChatMessage(
        id: messageId,
        content:
            'I\'m having trouble accessing review information. Please try again in a moment.',
        isUser: false,
        timestamp: timestamp,
        type: ChatMessageType.error,
      );
    }
  }

  // Bus query handling (existing functionality)
  static Future<ChatMessage> _handleBusQuery(
    String userMessage,
    String messageId,
    DateTime timestamp,
  ) async {
    try {
      final extractedInfo = _extractBusInfo(userMessage);

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

  // Utility functions (existing)
  static Map<String, String?> _extractBusInfo(String message) {
    final normalizedMessage = message.toLowerCase();
    String? from, to, time, busType;

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

    final timePattern = RegExp(
      r'(\d{1,2}):?(\d{2})?\s*(am|pm)?',
      caseSensitive: false,
    );
    final timeMatch = timePattern.firstMatch(normalizedMessage);
    if (timeMatch != null) {
      time = timeMatch.group(0);
    }

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

  // Helper functions
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

  static bool _isBusRelated(String message) {
    return _busRelatedKeywords.any((keyword) => message.contains(keyword));
  }

  static bool _isReviewRelated(String message) {
    return _reviewRelatedKeywords.any((keyword) => message.contains(keyword));
  }

  static bool _isAboutWritingReview(String message) {
    final keywords = ['write', 'create', 'add', 'submit', 'post', 'new review'];
    return keywords.any((keyword) => message.contains(keyword));
  }

  static bool _isAboutViewingReviews(String message) {
    final keywords = ['view', 'see', 'show', 'read', 'check', 'browse', 'look'];
    return keywords.any((keyword) => message.contains(keyword));
  }

  static bool _isAboutEditingReview(String message) {
    final keywords = ['edit', 'update', 'modify', 'change'];
    return keywords.any((keyword) => message.contains(keyword));
  }

  static bool _isAboutDeletingReview(String message) {
    final keywords = ['delete', 'remove', 'cancel'];
    return keywords.any((keyword) => message.contains(keyword));
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
      'How do I write a review?',
      'Show my reviews',
      'What can you do?',
      'Help me plan a trip',
    ];
  }
}
