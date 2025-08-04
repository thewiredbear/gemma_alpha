import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../data/models/textbook_chunk.dart';
import '../data/database/objectbox_store.dart';
import '../objectbox.g.dart';

class RagService {
  static RagService? _instance;
  late final ObjectBoxStore _objectBoxStore;
  late final Box<TextbookChunk> _textbookChunkBox;

  RagService._internal(this._objectBoxStore) {
    _textbookChunkBox = _objectBoxStore.store.box<TextbookChunk>();
  }

  static Future<RagService> getInstance(ObjectBoxStore objectBoxStore) async {
    if (_instance == null) {
      _instance = RagService._internal(objectBoxStore);
    }
    return _instance!;
  }

  /// Initialize the vector database with textbook data
  Future<void> ensureDbInitialized() async {
    print('🔍 Checking if RAG database is initialized...');
    
    // Check if the box is empty
    if (_textbookChunkBox.isEmpty()) {
      print('📚 Loading textbook vectors from assets...');
      await _loadTextbookVectors();
    } else {
      print('✅ RAG database already initialized with ${_textbookChunkBox.count()} chunks');
    }
  }

  /// Load textbook vectors from the JSON asset file
  Future<void> _loadTextbookVectors() async {
    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/textbook_vectors.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      print('📖 Found ${jsonData.length} textbook chunks to import');
      
      // Convert JSON data to TextbookChunk objects
      final List<TextbookChunk> chunks = [];
      for (final item in jsonData) {
        final chunk = TextbookChunk(
          text: item['text'] as String,
          embedding: List<double>.from(item['embedding'] as List),
        );
        chunks.add(chunk);
      }
      
      // Bulk insert all chunks
      _textbookChunkBox.putMany(chunks);
      
      print('✅ Successfully imported ${chunks.length} textbook chunks');
      
    } catch (e) {
      print('❌ Error loading textbook vectors: $e');
      rethrow;
    }
  }

  /// Calculate cosine similarity between two vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0.0 || normB == 0.0) return 0.0;
    
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Find relevant chunks using vector similarity search
  Future<List<TextbookChunk>> findRelevantChunks(
    List<double> queryVector, 
    int maxResults
  ) async {
    try {
      print('🔍 Searching for relevant chunks with ${queryVector.length}D query vector');
      
      // For now, implement a simple cosine similarity search
      // TODO: Use ObjectBox HNSW when the API is properly documented
      final allChunks = _textbookChunkBox.getAll();
      
      // Calculate cosine similarity for each chunk
      final similarities = <MapEntry<TextbookChunk, double>>[];
      
      for (final chunk in allChunks) {
        final similarity = _cosineSimilarity(queryVector, chunk.embedding);
        similarities.add(MapEntry(chunk, similarity));
      }
      
      // Sort by similarity (descending) and take top results
      similarities.sort((a, b) => b.value.compareTo(a.value));
      
      final topChunks = similarities
          .take(maxResults)
          .map((entry) => entry.key)
          .toList();
      
      print('✅ Found ${topChunks.length} relevant chunks');
      for (int i = 0; i < topChunks.length; i++) {
        final similarity = similarities[i].value;
        print('   ${i + 1}. Similarity: ${(similarity * 100).toStringAsFixed(1)}% - ${topChunks[i].text.substring(0, 50)}...');
      }
      
      return topChunks;
      
    } catch (e) {
      print('❌ Error finding relevant chunks: $e');
      return [];
    }
  }

  /// Get all textbook chunks (for debugging)
  List<TextbookChunk> getAllChunks() {
    return _textbookChunkBox.getAll();
  }

  /// Get the number of chunks in the database
  int getChunkCount() {
    return _textbookChunkBox.count();
  }

  /// Clear all textbook chunks (for testing)
  Future<void> clearDatabase() async {
    _textbookChunkBox.removeAll();
    print('🗑️ Cleared all textbook chunks');
  }

  /// Close the database connection
  void close() {
    // Don't close the store since it's shared with ObjectBoxStore
    _instance = null;
  }

  /// Get database statistics
  Map<String, dynamic> getStats() {
    return {
      'total_chunks': getChunkCount(),
      'database_path': 'Shared with ObjectBoxStore',
      'is_open': true,
    };
  }
}