import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/conversation.dart';
import '../models/message.dart';
import '../../objectbox.g.dart'; // Generated ObjectBox code

class ObjectBoxStore {
  static ObjectBoxStore? _instance;
  late final Store _store;
  late final Box<Conversation> _conversationBox;
  late final Box<Message> _messageBox;

  ObjectBoxStore._internal(this._store) {
    _conversationBox = _store.box<Conversation>();
    _messageBox = _store.box<Message>();
  }

  // Getter to expose the store for RagService
  Store get store => _store;

  static Future<ObjectBoxStore> getInstance() async {
    if (_instance == null) {
      // Get the application documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      
      // Create the ObjectBox store directory
      final storeDir = Directory(p.join(docsDir.path, 'objectbox'));
      
      // Open the ObjectBox store
      final store = await openStore(directory: storeDir.path);
      
      _instance = ObjectBoxStore._internal(store);
    }
    return _instance!;
  }

  // Conversation methods
  Future<void> saveConversation(Conversation conversation) async {
    _conversationBox.put(conversation);
  }

  Future<List<Conversation>> getAllConversations() async {
    return _conversationBox.getAll()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> deleteConversation(int conversationId) async {
    // Delete all messages in the conversation first
    final allMessages = _messageBox.getAll();
    final messagesToDelete = allMessages.where((msg) => msg.conversation.targetId == conversationId).toList();
    for (final message in messagesToDelete) {
      _messageBox.remove(message.id);
    }
    
    // Delete the conversation
    _conversationBox.remove(conversationId);
  }

  // Message methods
  Future<void> saveMessage(Message message) async {
    _messageBox.put(message);
  }

  Future<List<Message>> getMessagesForConversation(int conversationId) async {
    final allMessages = _messageBox.getAll();
    return allMessages.where((msg) => msg.conversation.targetId == conversationId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void close() {
    _store.close();
    _instance = null;
  }
}