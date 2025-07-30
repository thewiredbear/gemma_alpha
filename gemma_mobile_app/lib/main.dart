import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:permission_handler/permission_handler.dart';
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
    'Gemma 3n 2B (from Download folder)': 'gemma-3n-E2B-it-int4.task',
    'Gemma 3n 4B (from Download folder)': 'gemma-3n-E4B-it-int4.task',
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
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    } else {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
  }

  Future<void> _initializeModel() async {
    setState(() {
      _isLoading = true;
      _responseText = 'Checking storage permissions...';
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
        _responseText = 'Permission granted. Looking for $_selectedModelFileName in Download folder...';
      });

      final modelPath = '/storage/emulated/0/Download/$_selectedModelFileName';
      final file = File(modelPath);

      if (!await file.exists()) {
        throw Exception(
          'Model file not found at "$modelPath".\n\nPlease ensure the file is in your emulator\'s Download folder. You can drag and drop the file onto the emulator screen to transfer it.'
        );
      }
      
      await _gemma.modelManager.setModelPath(file.path);

      // --- THE CRITICAL CHANGE IS HERE ---
      // Use the CPU backend for the emulator to avoid OpenCL errors.
      _inferenceModel = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.cpu, // CHANGED FROM .gpu to .cpu
        supportImage: true, 
        maxNumImages: 1,
      );
      
      _chat = await _inferenceModel?.createChat();

      setState(() {
        _responseText = 'Model "$_selectedModelName" loaded successfully! Ready for prompts.';
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

  Future<void> _generateResponse() async {
    if (_chat == null || _promptController.text.trim().isEmpty) return;

    final promptText = _promptController.text;
    _promptController.clear();

    setState(() {
      _isLoading = true;
      _responseText = 'Generating response for: "$promptText"';
    });

    try {
      await _chat!.addQuery(Message.text(text: promptText, isUser: true));
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

  @override
  Widget build(BuildContext context) {
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
              
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.black26,
                  ),
                  child: _isLoading 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 15),
                          SelectableText(_responseText, textAlign: TextAlign.center),
                        ],
                      )
                    : SingleChildScrollView(
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