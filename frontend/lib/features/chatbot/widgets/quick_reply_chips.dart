import 'package:flutter/material.dart';

class QuickReplyChips extends StatelessWidget {
  final List<String> replies;
  final Function(String) onReplySelected;

  const QuickReplyChips({
    super.key,
    required this.replies,
    required this.onReplySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick replies:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: replies.map((reply) => _buildChip(reply)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String reply) {
    return ActionChip(
      label: Text(
        reply,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: const Color(0xFF374151),
      side: const BorderSide(color: Color(0xFF6B7280)),
      onPressed: () => onReplySelected(reply),
    );
  }
}


