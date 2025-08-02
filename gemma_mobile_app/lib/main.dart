import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemma 3n Local Test',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0b2351),
        scaffoldBackgroundColor: const Color(0xFF0b2351),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterGemmaPlugin _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _inferenceModel;
  InferenceChat? _chat;
  final TextEditingController _promptController = TextEditingController();
  String _responseText = '';
  bool _isLoading = false;
  
  final Map<String, String> _models = {
    // Start with the 2B model for better performance on mobile devices
    'Gemma 3n 2B': 'gemma-3n-E2B-it-int4.task',
    'Gemma 3n 4B': 'gemma-3n-E4B-it-int4.task',
  };
  late String _selectedModelName;
  late String _selectedModelFileName;

  @override
  void initState() {
    super.initState();
    _selectedModelName = _models.keys.first;
    _selectedModelFileName = _models.values.first;
    _initializeModel();
  }

  Future<bool> _requestStoragePermission() async {
    // Only request permissions on Android
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      } else {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }
    }
    // iOS doesn't need these permissions for app documents directory
    return true;
  }

  Future<String> _getModelPath() async {
    if (Platform.isIOS) {
      // On iOS, check multiple possible locations
      final documentsDir = await getApplicationDocumentsDirectory();
      final possiblePaths = [
        '${documentsDir.path}/$_selectedModelFileName',
        '${documentsDir.path}/Downloads/$_selectedModelFileName',
      ];
      
      // Return the first path where the file exists
      for (String path in possiblePaths) {
        if (await File(path).exists()) {
          return path;
        }
      }
      
      // If file doesn't exist, return the documents directory path
      return '${documentsDir.path}/$_selectedModelFileName';
    } else {
      // Android path
      return '/storage/emulated/0/Download/$_selectedModelFileName';
    }
  }

  String _getInstructions() {
    if (Platform.isIOS) {
      return 'Please add the model file to your device using:\n'
             '1. iTunes File Sharing\n'
             '2. AirDrop to your device\n'
             '3. Drag & drop to iOS Simulator\n'
             '4. Files app (if available)';
    } else {
      return 'Please ensure the model file is in your device\'s Download folder.';
    }
  }

  Future<void> _initializeModel() async {
    setState(() {
      _isLoading = true;
      _responseText = 'Checking permissions and model file...';
      _chat = null;
      _inferenceModel = null;
    });

    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception(
          "Storage permission denied. Please grant 'All files access' permission for this app in your device settings and restart the app."
        );
      }
      
      setState(() {
        _responseText = 'Permission granted. Looking for $_selectedModelFileName...';
      });

      final modelPath = await _getModelPath();
      final file = File(modelPath);

      if (!await file.exists()) {
        throw Exception(
          'Model file not found at "$modelPath".\n\n${_getInstructions()}'
        );
      }
      
      setState(() {
        _responseText = 'Model file found. Loading model...';
      });
      
      await _gemma.modelManager.setModelPath(file.path);

      _inferenceModel = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.cpu, // Use CPU for broad compatibility
        supportImage: false, 
      );
      
      _chat = await _inferenceModel?.createChat();

      setState(() {
        _responseText = 'Model "$_selectedModelName" loaded successfully! Ready for prompts.\n\nModel path: $modelPath';
      });
    } catch (e) {
      setState(() {
        _responseText = 'ERROR: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Generates a response from the model using a streaming method.
  Future<void> _generateResponse() async {
    if (_chat == null || _promptController.text.trim().isEmpty) return;

    final promptText = _promptController.text;
    _promptController.clear();

    setState(() {
      _isLoading = true;
      _responseText = ''; // Start with an empty string for the streaming text
    });

    try {
      // Step 1: Add the user's message to the chat history.
      // The model will use this history to generate its response.
      await _chat!.addQuery(Message.text(text: promptText, isUser: true));

      // Step 2: Call the streaming method. Based on the library source,
      // the correct method is `generateChatResponseAsync`.
      final stream = _chat!.generateChatResponseAsync();

      // Step 3: Listen to the stream and update the UI with each new token.
      await for (final response in stream) {
        if (response is TextResponse) {
          setState(() {
            _responseText += response.token;
          });
        }
      }
    } catch (e) {
      setState(() {
        _responseText = 'Error during generation: $e';
      });
    } finally {
      // This runs after the stream is closed (successfully or with an error).
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gemma 3n Local Test (${Platform.operatingSystem})'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white10,
                ),
                child: DropdownButton<String>(
                  value: _selectedModelName,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  onChanged: _isLoading ? null : (String? newValue) {
                    if (newValue != null && _selectedModelName != newValue) {
                      setState(() {
                        _selectedModelName = newValue;
                        _selectedModelFileName = _models[newValue]!;
                        _initializeModel();
                      });
                    }
                  },
                  items: _models.keys.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Enter your prompt',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading && _chat != null,
                maxLines: 3,
                onSubmitted: (_) => _generateResponse(),
              ),
              const SizedBox(height: 20),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: (_isLoading || _chat == null) ? null : _generateResponse,
                child: const Text('Generate Response'),
              ),
              const SizedBox(height: 20),
              
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Response:', style: TextStyle(fontWeight: FontWeight.bold))
              ),
              const SizedBox(height: 10),
              
              // This UI block is designed for a good streaming experience.
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.black26,
                  ),
                  child: SingleChildScrollView(
                    reverse: true, // Keeps the view scrolled to the bottom
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(_responseText),
                        // Show a blinking cursor while the model is generating
                        if (_isLoading)
                          const BlinkingCursor(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple widget that simulates a blinking cursor.
class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({super.key});

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 20,
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}