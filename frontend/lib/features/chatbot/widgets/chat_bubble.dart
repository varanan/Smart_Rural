import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../../../models/bus_timetable.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String)? onQuickReply;

  const ChatBubble({
    super.key,
    required this.message,
    this.onQuickReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2563EB),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? const Color(0xFFF97316)
                    : const Color(0xFF374151),
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isUser 
                      ? const Radius.circular(18) 
                      : const Radius.circular(4),
                  bottomRight: message.isUser 
                      ? const Radius.circular(4) 
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == ChatMessageType.busSchedule)
                    _buildBusScheduleContent()
                  else
                    _buildTextContent(),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white70 
                          : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[600],
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    Color textColor = message.isUser ? Colors.white : Colors.white;
    
    if (message.type == ChatMessageType.error) {
      textColor = Colors.red[300]!;
    }

    return Text(
      message.content,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _buildBusScheduleContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        
        if (message.metadata?['timetables'] != null) ...[
          const SizedBox(height: 12),
          ...(_buildBusCards(message.metadata!['timetables'])),
        ],
      ],
    );
  }

  List<Widget> _buildBusCards(List<dynamic> timetablesJson) {
    final timetables = timetablesJson
        .map((json) => BusTimeTable.fromJson(json))
        .take(3) // Show max 3 cards in chat
        .toList();

    return timetables.map((timetable) => _buildBusCard(timetable)).toList();
  }

  Widget _buildBusCard(BusTimeTable timetable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bus type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getBusTypeColor(timetable.busType),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              timetable.busType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Route
          Row(
            children: [
              Expanded(
                child: Text(
                  timetable.from,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: Color(0xFFF97316),
                size: 16,
              ),
              Expanded(
                child: Text(
                  timetable.to,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dep: ${timetable.startTime}',
                style: const TextStyle(
                  color: Color(0xFFF97316),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Arr: ${timetable.endTime}',
                style: const TextStyle(
                  color: Color(0xFFF97316),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBusTypeColor(String busType) {
    switch (busType.toLowerCase()) {
      case 'express':
        return Colors.red;
      case 'luxury':
        return Colors.purple;
      case 'semi-luxury':
        return Colors.blue;
      case 'intercity':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}


