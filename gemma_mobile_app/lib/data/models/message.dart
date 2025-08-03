import 'package:objectbox/objectbox.dart';
import 'conversation.dart';

@Entity()
class Message {
  @Id()
  int id = 0;
  
  String content;
  bool isFromUser;
  DateTime timestamp;
  
  // Optional analytics data
  int? tokenCount;
  int? processingTimeMs;
  
  // Back-reference to conversation
  final conversation = ToOne<Conversation>();
  
  Message({
    required this.content,
    required this.isFromUser,
    DateTime? timestamp,
    this.tokenCount,
    this.processingTimeMs,
  }) : timestamp = timestamp ?? DateTime.now();
  
  bool get isUserMessage => isFromUser;
  bool get isAiMessage => !isFromUser;
  
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}