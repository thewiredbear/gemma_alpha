import 'package:flutter/foundation.dart';
import '../../../services/gemma_services.dart';
import '../../../data/database/objectbox_store.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/message.dart';
import '../../../core/constants/model_constants.dart';

class ChatProvider extends ChangeNotifier {
  final GemmaService _gemmaService;
  final ObjectBoxStore _objectBoxStore;
  
  ChatProvider({
    required GemmaService gemmaService,
    required ObjectBoxStore objectBoxStore,
  }) : _gemmaService = gemmaService,
       _objectBoxStore = objectBoxStore {
    _initialize();
  }
  
  // State variables
  String _selectedModelName = ModelConstants.defaultModelName;
  String _currentResponse = '';
  bool _isLoading = false;
  String _statusMessage = '';
  Conversation? _currentConversation;
  List<Message> _messages = [];
  
  // Getters
  String get selectedModelName => _selectedModelName;
  String get currentResponse => _currentResponse;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  bool get isModelReady => _gemmaService.isModelLoaded;
  List<Message> get messages => _messages;
  Conversation? get currentConversation => _currentConversation;
  
  Future<void> _initialize() async {
    await initializeModel(_selectedModelName);
  }
  
  Future<void> initializeModel(String modelName) async {
    _setLoading(true);
    _setStatusMessage('Initializing model...');
    
    try {
      await _gemmaService.initializeModel(modelName);
      _selectedModelName = modelName;
      _setStatusMessage('Model "$modelName" loaded successfully!');
      
      // Create new conversation when model changes
      await _createNewConversation();
      
    } catch (e) {
      _setStatusMessage('ERROR: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> generateResponse(String prompt) async {
    if (!_gemmaService.isModelLoaded || prompt.trim().isEmpty) return;
    
    _setLoading(true);
    _currentResponse = '';
    
    try {
      // Save user message
      final userMessage = Message(
        content: prompt,
        isFromUser: true,
      );
      
      if (_currentConversation != null) {
        userMessage.conversation.target = _currentConversation;
        await _objectBoxStore.saveMessage(userMessage);
        _messages.add(userMessage);
        notifyListeners();
      }
      
      // Generate AI response
      final responseBuffer = StringBuffer();
      final startTime = DateTime.now();
      
      await for (final token in _gemmaService.generateResponse(prompt)) {
        responseBuffer.write(token);
        _currentResponse = responseBuffer.toString();
        notifyListeners();
      }
      
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;
      
      // Save AI response
      if (_currentConversation != null) {
        final aiMessage = Message(
          content: _currentResponse,
          isFromUser: false,
          processingTimeMs: processingTime,
        );
        aiMessage.conversation.target = _currentConversation;
        await _objectBoxStore.saveMessage(aiMessage);
        _messages.add(aiMessage);
        
        // Update conversation timestamp
        _currentConversation!.updateTimestamp();
        await _objectBoxStore.saveConversation(_currentConversation!);
      }
      
    } catch (e) {
      _currentResponse = 'Error during generation: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> _createNewConversation() async {
    _currentConversation = Conversation(
      title: 'Chat with $_selectedModelName',
      modelName: _selectedModelName,
    );
    
    await _objectBoxStore.saveConversation(_currentConversation!);
    _messages.clear();
    _currentResponse = '';
    notifyListeners();
  }
  
  Future<void> loadConversation(Conversation conversation) async {
    _currentConversation = conversation;
    _messages = await _objectBoxStore.getMessagesForConversation(conversation.id);
    _currentResponse = '';
    notifyListeners();
  }
  
  Future<List<Conversation>> getConversationHistory() async {
    return _objectBoxStore.getAllConversations();
  }
  
  Future<void> deleteConversation(Conversation conversation) async {
    await _objectBoxStore.deleteConversation(conversation.id);
    if (_currentConversation?.id == conversation.id) {
      await _createNewConversation();
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setStatusMessage(String message) {
    _statusMessage = message;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _gemmaService.dispose();
    super.dispose();
  }
}