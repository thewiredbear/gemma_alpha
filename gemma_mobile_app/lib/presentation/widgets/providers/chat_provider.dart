import 'package:flutter/foundation.dart';
import '../../../services/gemma_services.dart';
import '../../../data/database/objectbox_store.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/message.dart';
import '../../../core/constants/model_constants.dart';
import '../../../services/rag_service.dart';
import '../../../services/text_embedder_service.dart';

class ChatProvider extends ChangeNotifier {
  final GemmaService _gemmaService;
  final ObjectBoxStore _objectBoxStore;
  final RagService _ragService;
  final TextEmbedderService _textEmbedderService;
  
  ChatProvider({
    required GemmaService gemmaService,
    required ObjectBoxStore objectBoxStore,
    required RagService ragService,
    required TextEmbedderService textEmbedderService,
  }) : _gemmaService = gemmaService,
       _objectBoxStore = objectBoxStore,
       _ragService = ragService,
       _textEmbedderService = textEmbedderService {
    _initialize();
  }
  
  // State variables
  String _selectedModelName = ModelConstants.defaultModelName;
  String _currentResponse = '';
  bool _isLoading = false;
  String _statusMessage = '';
  Conversation? _currentConversation;
  List<Message> _messages = [];
  bool _ragEnabled = true; // RAG is enabled by default
  
  // Getters
  String get selectedModelName => _selectedModelName;
  String get currentResponse => _currentResponse;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  bool get isModelReady => _gemmaService.isModelLoaded;
  List<Message> get messages => _messages;
  Conversation? get currentConversation => _currentConversation;
  bool get ragEnabled => _ragEnabled;
  
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
      
      // Prepare the final prompt (with or without RAG)
      String finalPrompt = prompt;
      
      if (_ragEnabled) {
        _setStatusMessage('Finding relevant information...');
        finalPrompt = await _buildRagPrompt(prompt);
      }
      
      // Generate AI response
      _setStatusMessage('Generating response...');
      final responseBuffer = StringBuffer();
      final startTime = DateTime.now();
      
      await for (final token in _gemmaService.generateResponse(finalPrompt)) {
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
      
      _setStatusMessage('');
      
    } catch (e) {
      _currentResponse = 'Error during generation: $e';
      _setStatusMessage('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Build RAG-enhanced prompt with relevant context
  Future<String> _buildRagPrompt(String userQuery) async {
    try {
      // Step 1: Embed the user's query
      _setStatusMessage('Embedding query...');
      final queryVector = await _textEmbedderService.embedText(userQuery);
      
      if (queryVector == null) {
        print('⚠️ Could not embed query, falling back to direct prompt');
        return userQuery;
      }
      
      // Step 2: Search the vector database
      _setStatusMessage('Searching textbook...');
      final relevantChunks = await _ragService.findRelevantChunks(queryVector, 3);
      
      if (relevantChunks.isEmpty) {
        print('⚠️ No relevant chunks found, using direct prompt');
        return userQuery;
      }
      
      // Step 3: Construct the augmented prompt
      _setStatusMessage('Building context...');
      final contextBuffer = StringBuffer();
      contextBuffer.writeln('Based on the following context from a biology textbook, answer the user\'s question:');
      contextBuffer.writeln();
      contextBuffer.writeln('Context:');
      
      for (int i = 0; i < relevantChunks.length; i++) {
        contextBuffer.writeln('${i + 1}. ${relevantChunks[i].text}');
        contextBuffer.writeln();
      }
      
      contextBuffer.writeln('Question: $userQuery');
      contextBuffer.writeln();
      contextBuffer.writeln('Please provide a comprehensive answer based on the context above. If the context doesn\'t contain relevant information, say so and provide what general knowledge you can.');
      
      final finalPrompt = contextBuffer.toString();
      print('🔍 RAG prompt built with ${relevantChunks.length} relevant chunks');
      
      return finalPrompt;
      
    } catch (e) {
      print('❌ Error building RAG prompt: $e');
      return userQuery;
    }
  }

  /// Toggle RAG functionality
  void toggleRag() {
    _ragEnabled = !_ragEnabled;
    print('🔄 RAG ${_ragEnabled ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  /// Get RAG service statistics
  Map<String, dynamic> getRagStats() {
    return _ragService.getStats();
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