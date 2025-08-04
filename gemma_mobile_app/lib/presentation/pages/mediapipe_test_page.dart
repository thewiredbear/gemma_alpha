import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/text_embedder_service.dart';

class MediaPipeTestPage extends StatefulWidget {
  @override
  _MediaPipeTestPageState createState() => _MediaPipeTestPageState();
}

class _MediaPipeTestPageState extends State<MediaPipeTestPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _text2Controller = TextEditingController();
  
  late TextEmbedderService _embedder;
  
  String _status = 'Initializing embedder...';
  List<double>? _embedding;
  double? _similarity;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _textController.text = 'The quick brown fox jumps over the lazy dog';
    _text2Controller.text = 'A fast red fox leaps above the sleepy canine';
    _initEmbedder();
  }
  
  Future<void> _initEmbedder() async {
    _embedder = TextEmbedderService();
  await _embedder.initialize(modelAssetPath: 'assets/models/universal_sentence_encoder.tflite');
    
    setState(() {
      _status = _embedder.isLoaded 
          ? '✅ Universal Sentence Encoder loaded'
          : '❌ Model not found (add universal_sentence_encoder.tflite to assets/)';
    });
  }
  
  Future<void> _generateEmbedding() async {
    if (_textController.text.isEmpty || !_embedder.isLoaded) return;
    
    setState(() {
      _isLoading = true;
      _embedding = null;
    });
    
    final embedding = await _embedder.embedText(_textController.text);
    
    setState(() {
      _embedding = embedding;
      _isLoading = false;
    });
  }
  
 Future<void> _calculateSimilarity() async {
  // ... guard clauses ...
  setState(() { _isLoading = true; _similarity = null; });
  
  final vec1 = await _embedder.embedText(_textController.text);
  final vec2 = await _embedder.embedText(_text2Controller.text);
  
  if (vec1 != null && vec2 != null) {
    final similarity = _embedder.calculateSimilarity(vec1, vec2);
    setState(() { _similarity = similarity; });
  } else {
    // Handle error, maybe show a SnackBar
  }
  
  setState(() { _isLoading = false; });
}
  void _copyVector() {
    if (_embedding != null) {
      final vectorString = _embedding!.toString();
      Clipboard.setData(ClipboardData(text: vectorString));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vector copied to clipboard!')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text Embedder'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _embedder.isLoaded ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _embedder.isLoaded ? Icons.check_circle : Icons.error,
                      color: _embedder.isLoaded ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text(_status)),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Input Section
            Text(
              '📝 Text to Embed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Enter text',
                border: OutlineInputBorder(),
                hintText: 'Type your text here...',
              ),
            ),
            
            SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _embedder.isLoaded && !_isLoading ? _generateEmbedding : null,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.psychology),
                label: Text(_isLoading ? 'Generating...' : 'Generate Embedding'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            // Embedding Result
            if (_embedding != null) ...[
              SizedBox(height: 24),
              Text(
                '🔢 Embedding Vector',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dimensions: ${_embedding!.length}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: _copyVector,
                            icon: Icon(Icons.copy, size: 16),
                            label: Text('Copy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: Size(80, 32),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 12),
                      
                      Text('First 10 values:', style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          _embedding!.take(10).map((v) => v.toStringAsFixed(4)).join(', ') + '...',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Vector Visualization
                      Text('Vector Visualization (first 20 dimensions):', style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(height: 8),
                      
                      Container(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _embedding!.length.clamp(0, 20),
                          itemBuilder: (context, index) {
                            final value = _embedding![index];
                            final normalizedHeight = ((value.abs() * 60) + 10).clamp(10.0, 70.0);
                            
                            return Container(
                              width: 12,
                              margin: EdgeInsets.only(right: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: normalizedHeight,
                                    decoration: BoxDecoration(
                                      color: value >= 0 ? Colors.blue[400] : Colors.red[400],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${index + 1}',
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 32),
            
            // Similarity Section
            Text(
              '🔍 Text Similarity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            
            TextField(
              controller: _text2Controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Second text for comparison',
                border: OutlineInputBorder(),
                hintText: 'Enter another text to compare...',
              ),
            ),
            
            SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _embedder.isLoaded && !_isLoading ? _calculateSimilarity : null,
                icon: Icon(Icons.compare_arrows),
                label: Text('Calculate Similarity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            // Similarity Result
            if (_similarity != null) ...[
              SizedBox(height: 20),
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Cosine Similarity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      
                      Text(
                        '${(_similarity! * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      LinearProgressIndicator(
                        value: (_similarity! + 1) / 2, // Normalize from [-1,1] to [0,1] for display
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                        minHeight: 8,
                      ),
                      
                      SizedBox(height: 8),
                      
                      Text(
                        'Range: -1 (opposite) to +1 (identical)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 32),
            
            // Setup Instructions
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber[700]),
                        SizedBox(width: 8),
                        Text(
                          'Setup Instructions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('1. Download universal_sentence_encoder.tflite'),
                    Text('2. Place it in your project\'s assets/ folder'),
                    Text('3. Add "assets/" to your pubspec.yaml'),
                    Text('4. Run flutter pub get and rebuild'),
                    SizedBox(height: 8),
                    Text(
                      '💡 Without the model file, embeddings are not available',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _text2Controller.dispose();
    _embedder.dispose();
    super.dispose();
  }
}