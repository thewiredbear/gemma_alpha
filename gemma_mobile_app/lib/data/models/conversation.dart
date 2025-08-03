import 'package:objectbox/objectbox.dart';
import 'message.dart';

@Entity()
class Conversation {
  @Id()
  int id = 0;
  
  String title;
  String modelName;
  DateTime createdAt;
  DateTime updatedAt;
  
  // Relation to messages
  final messages = ToMany<Message>();
  
  Conversation({
    required this.title,
    required this.modelName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  void updateTimestamp() {
    updatedAt = DateTime.now();
  }
  
  String get preview {
    if (messages.isEmpty) return 'New conversation';
    final lastMessage = messages.last;
    return lastMessage.content.length > 50
        ? '${lastMessage.content.substring(0, 50)}...'
        : lastMessage.content;
  }
}