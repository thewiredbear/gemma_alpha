import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/model_constants.dart';

class GemmaService {
  final FlutterGemmaPlugin _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _inferenceModel;
  InferenceChat? _chat;
  String _currentModelName = ModelConstants.defaultModelName;
  
  String get currentModelName => _currentModelName;
  bool get isModelLoaded => _inferenceModel != null && _chat != null;
  
  /// Check which model files are available
  Future<List<String>> getAvailableModels() async {
    print('🔍 Checking for available models...');
    final availableModels = <String>[];
    
    for (final entry in ModelConstants.availableModels.entries) {
      final modelName = entry.key;
      final fileName = entry.value;
      
      try {
        final modelPath = await _getModelPath(fileName);
        final file = File(modelPath);
        
        print('🎯 Checking: $modelPath');
        
        if (await file.exists()) {
          final stat = await file.stat();
          final sizeGB = (stat.size / (1024 * 1024 * 1024)).toStringAsFixed(2);
          print('✅ Found $modelName: ${sizeGB}GB');
          availableModels.add(modelName);
        } else {
          print('❌ Not found: $modelName');
        }
      } catch (e) {
        print('❌ Error checking $modelName: $e');
      }
    }
    
    print('📋 Available models: ${availableModels.join(", ")}');
    return availableModels;
  }
  
  Future<String> _getModelPath(String fileName) async {
    // For iOS, check multiple possible locations
    final documentsDir = await getApplicationDocumentsDirectory();
    
    print('🔍 Searching for model file: $fileName');
    print('📁 App Documents directory: ${documentsDir.path}');
    
    // List all files in Documents directory for debugging
    try {
      final documentsContents = await Directory(documentsDir.path).list().toList();
      print('📋 Files in app Documents directory:');
      for (final entity in documentsContents) {
        if (entity is File) {
          final stat = await entity.stat();
          final sizeMB = (stat.size / (1024 * 1024)).toStringAsFixed(1);
          print('   📄 ${entity.path.split('/').last} (${sizeMB}MB)');
        } else if (entity is Directory) {
          print('   📁 ${entity.path.split('/').last}/');
        }
      }
    } catch (e) {
      print('❌ Error listing Documents directory: $e');
    }
    
    // Try different possible paths within app sandbox
    final possiblePaths = [
      '${documentsDir.path}/$fileName',
      '${documentsDir.path}/Downloads/$fileName',
      '${documentsDir.path}/Files/$fileName',
      '${documentsDir.path}/Inbox/$fileName',
    ];
    
    // Check each possible path
    for (final path in possiblePaths) {
      print('🎯 Checking path: $path');
      final file = File(path);
      if (await file.exists()) {
        print('✅ Found model at: $path');
        return path;
      }
    }
    
    // Try to find any .task files in Documents directory (including subdirectories)
    try {
      print('🔍 Searching for any .task files in app Documents (including subdirectories)...');
      final allFiles = await Directory(documentsDir.path)
          .list(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.task'))
          .cast<File>()
          .toList();
      
      if (allFiles.isNotEmpty) {
        print('📋 Found ${allFiles.length} .task file(s):');
        for (final file in allFiles) {
          final foundFileName = file.path.split('/').last;
          final stat = await file.stat();
          final sizeMB = (stat.size / (1024 * 1024)).toStringAsFixed(1);
          final relativePath = file.path.replaceFirst(documentsDir.path, '');
          print('   🎯 $foundFileName (${sizeMB}MB) at $relativePath');
          
          // If this matches our target file, return it
          if (foundFileName == fileName) {
            print('✅ Found exact matching model file: ${file.path}');
            return file.path;
          }
          
          // Also check for any .task file (since we only support 2B model now)
          if (foundFileName.contains('2B') || foundFileName.contains('2b')) {
            print('✅ Found compatible 2B model file: ${file.path}');
            return file.path;
          }
        }
        
        // If no exact match, but we found .task files, suggest using the first one
        if (allFiles.isNotEmpty) {
          final firstFile = allFiles.first;
          final foundFileName = firstFile.path.split('/').last;
          final stat = await firstFile.stat();
          final sizeMB = (stat.size / (1024 * 1024)).toStringAsFixed(1);
          print('💡 No exact match found, but detected: $foundFileName (${sizeMB}MB)');
          print('🔄 You can try using this file instead');
          return firstFile.path;
        }
      } else {
        print('❌ No .task files found in Documents directory');
      }
    } catch (e) {
      print('❌ Error searching for .task files: $e');
    }
    
    // If not found, provide helpful instructions
    print('❌ Model file not found in app Documents directory');
    print('');
    print('📱 INSTRUCTIONS TO MOVE MODEL FILE:');
    print('   1. Open Files app on your iPhone');
    print('   2. Navigate to Downloads folder');
    print('   3. Find your model file: $fileName');
    print('   4. Tap and hold the file, select "Share"');
    print('   5. Choose "Save to Files"');
    print('   6. Navigate to "On My iPhone" > "Gemma Mobile App"');
    print('   7. Tap "Save" to copy the file to the app');
    print('');
    print('💡 Alternative: Use iTunes File Sharing to copy the file');
    print('   Connect iPhone to computer, open iTunes/Finder');
    print('   Select device > Apps > File Sharing > Gemma Mobile App');
    print('   Drag the model file from Downloads to the app folder');
    
    return '${documentsDir.path}/$fileName';
  }
  
  Future<void> initializeModel(String modelName) async {
    print('🚀 Initializing model: $modelName');
    _currentModelName = modelName;
    final modelFileName = ModelConstants.availableModels[modelName];
    
    if (modelFileName == null) {
      throw Exception('Unknown model: $modelName');
    }
    
    final modelPath = await _getModelPath(modelFileName);
    final file = File(modelPath);
    
    print('📍 Model path: $modelPath');
    
    // Check if file exists
    if (!await file.exists()) {
      throw Exception('Model file not found at: $modelPath');
    }
    
    // Check file size and permissions
    try {
      final stat = await file.stat();
      final sizeGB = (stat.size / (1024 * 1024 * 1024)).toStringAsFixed(2);
      final sizeMB = (stat.size / (1024 * 1024)).toStringAsFixed(1);
      print('📊 File size: ${sizeGB}GB (${sizeMB}MB)');
      print('📅 Modified: ${stat.modified}');
      
      // Verify file is not empty or corrupted
      if (stat.size < 1000000) { // Less than 1MB is suspicious
        throw Exception('Model file seems too small (${sizeMB}MB) - possibly corrupted');
      }
      
      print('✅ File size looks reasonable');
      
    } catch (e) {
      print('❌ Error reading file info: $e');
      throw Exception('Cannot access model file: $e');
    }
    
    print('⚡ Setting model path in Gemma...');
    
    try {
      await _gemma.modelManager.setModelPath(file.path);
      print('✅ Model path set successfully in Gemma');
    } catch (e) {
      print('❌ Error setting model path: $e');
      throw Exception('Failed to set model path in Gemma: $e');
    }
    
    print('🧠 Creating inference model...');
    print('   Using CPU backend for compatibility');
    print('   Model type: Gemma IT (Instruction Tuned)');
    
    try {
      _inferenceModel = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.cpu,
        supportImage: false,
      );
      print('✅ Inference model created successfully');
    } catch (e) {
      print('❌ Error creating inference model: $e');
      print('💡 This might be due to:');
      print('   - Device memory constraints');
      print('   - Corrupted model file');
      print('   - Incompatible model format');
      throw Exception('Failed to create inference model: $e');
    }
    
    print('💬 Creating chat interface...');
    
    try {
      _chat = await _inferenceModel?.createChat();
      if (_chat != null) {
        print('✅ Chat interface created successfully');
      } else {
        throw Exception('Chat interface is null after creation');
      }
    } catch (e) {
      print('❌ Error creating chat interface: $e');
      throw Exception('Failed to create chat interface: $e');
    }
    
    print('🎉 Model "$modelName" loaded successfully!');
    print('💾 Memory usage may be high - this is normal for AI models');
  }
  
  Stream<String> generateResponse(String prompt) async* {
    if (_chat == null) {
      throw Exception('Model not initialized');
    }
    
    final trimmedPrompt = prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt;
    print('💭 Generating response for: $trimmedPrompt');
    
    try {
      await _chat!.addQuery(Message.text(text: prompt, isUser: true));
      final stream = _chat!.generateChatResponseAsync();
      
      await for (final response in stream) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
      
      print('✅ Response generation completed');
    } catch (e) {
      print('❌ Error during response generation: $e');
      throw Exception('Failed to generate response: $e');
    }
  }
  
  /// Get the first available model, or null if none found
  Future<String?> getFirstAvailableModel() async {
    final available = await getAvailableModels();
    return available.isNotEmpty ? available.first : null;
  }
  
  /// Check if a specific model is available
  Future<bool> isModelAvailable(String modelName) async {
    final available = await getAvailableModels();
    return available.contains(modelName);
  }
  
  /// Get detailed info about the current model
  String getModelInfo() {
    if (!isModelLoaded) {
      return 'No model loaded';
    }
    
    return 'Model: $_currentModelName\n'
           'Status: Loaded and ready\n'
           'Backend: CPU\n'
           'Type: Instruction Tuned';
  }
  
  void dispose() {
    print('🧹 Disposing Gemma service...');
    _inferenceModel = null;
    _chat = null;
    print('✅ Gemma service disposed');
  }
}