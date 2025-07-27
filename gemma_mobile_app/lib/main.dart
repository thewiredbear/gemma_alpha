import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:permission_handler/permission_handler.dart'; // NEW: Import the permission handler

// Dart/IO imports
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
  // --- STATE VARIABLES ---
  final FlutterGemmaPlugin _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _inferenceModel;
  InferenceChat? _chat;
  final TextEditingController _promptController = TextEditingController();
  String _responseText = '';
  bool _isLoading = false;
  final String _modelFileName = 'gemma-3n-E4B-it-int4.task';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // --- CORE LOGIC ---

  // NEW: A function dedicated to asking for storage permission.
  Future<bool> _requestStoragePermission() async {
    // Check the status of the storage permission.
    var status = await Permission.storage.status;
    
    // If permission is not granted, request it.
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    
    // Return true if permission is granted, false otherwise.
    return status.isGranted;
  }

  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
      _responseText = 'Checking storage permissions...';
    });

    try {
      // Step 1: Request permission BEFORE trying to access any files.
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception("Storage permission denied. Please grant permission in app settings and restart.");
      }

      setState(() {
        _responseText = 'Permission granted. Loading $_modelFileName from device storage...';
      });

      // Step 2: Get the path to the model file on the device.
      final modelPath = await _getModelPathOnDevice(_modelFileName);

      // Step 3: Set the model path in the Gemma plugin.
      await _gemma.modelManager.setModelPath(modelPath);

      // Step 4: Create the inference model instance.
      _inferenceModel = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.gpu,
      );
      
      // Step 5: Create a chat session.
      _chat = await _inferenceModel?.createChat();

      setState(() {
        _responseText = 'Model loaded successfully! Ready for prompts.';
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

  Future<String> _getModelPathOnDevice(String modelFileName) async {
    final path = '/storage/emulated/0/Download/$modelFileName';
    final file = File(path);

    if (!await file.exists()) {
      throw Exception(
        'Model file not found at $path.\n\nPlease ensure you have manually uploaded the model to the emulator\'s Download folder.'
      );
    }
    return file.path;
  }

  Future<void> _generateResponse() async {
    if (_chat == null || _promptController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _responseText = 'Generating response...';
    });

    try {
      await _chat!.addQueryChunk(Message.text(text: _promptController.text, isUser: true));
      final response = await _chat!.generateChatResponse();
      
      setState(() {
          if (response is TextResponse) {
             _responseText = response.token;
          } else {
             _responseText = 'Model returned a non-text response.';
          }
      });
    } catch (e) {
      setState(() {
        _responseText = 'Error during generation: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- UI WIDGETS ---
  @override
  Widget build(BuildContext context) {
    // ... [The UI build method remains the same as the last version] ...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemma 3n Local Test'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white10,
                ),
                child: Text(
                  'Testing Model: $_modelFileName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
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
              ),
              const SizedBox(height: 20),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: (_isLoading || _chat == null) ? null : _generateResponse,
                child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                  : const Text('Generate Response'),
              ),
              const SizedBox(height: 20),
              
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Response:', style: TextStyle(fontWeight: FontWeight.bold))
              ),
              const SizedBox(height: 10),
              
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(_responseText),
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