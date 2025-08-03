import 'package:flutter/material.dart';
import '../../data/models/message.dart';

class ChatMessage extends StatelessWidget {
  final Message message;

  const ChatMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: message.isUserMessage 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            child: Icon(
              message.isUserMessage ? Icons.person : Icons.smart_toy,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          
          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with sender and time
                Row(
                  children: [
                    Text(
                      message.isUserMessage ? 'You' : 'Gemma',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.formattedTime,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    if (message.processingTimeMs != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${message.processingTimeMs}ms)',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                
                // Message content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: message.isUserMessage
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SelectableText(
                    message.content,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}