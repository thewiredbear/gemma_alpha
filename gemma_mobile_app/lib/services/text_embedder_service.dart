import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';

class TextEmbedderService {
  static const MethodChannel _channel = MethodChannel('mediapipe_text_embedder');

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Initializes the native MediaPipe TextEmbedder with the specified model.
  /// The [modelAssetPath] is the path to the model file in your Flutter assets,
  /// e.g., 'assets/models/universal_sentence_encoder.tflite'.
  Future<void> initialize({required String modelAssetPath}) async {
    try {
      print('🚀 Initializing native MediaPipe TextEmbedder...');
      final bool success = await _channel.invokeMethod('initialize', {
        'modelPath': modelAssetPath,
      });
      _isLoaded = success;
      if (_isLoaded) {
        print('✅ Native MediaPipe TextEmbedder loaded successfully.');
      } else {
         print('❌ Native MediaPipe TextEmbedder failed to load. Check native logs.');
      }
    } on PlatformException catch (e) {
      print('❌ Failed to initialize native MediaPipe: ${e.message}');
      _isLoaded = false;
    }
  }

  /// Generates a vector embedding for the given text using the native MediaPipe implementation.
  /// Returns null if the service is not loaded or if an error occurs.
  Future<List<double>?> embedText(String text) async {
    if (!_isLoaded) {
      print('⚠️ Cannot embed text: service not loaded.');
      return null;
    }
    try {
      // The native code returns a List<double> (DoubleArray in Kotlin, [Double] in Swift)
      final List<dynamic>? vector = await _channel.invokeMethod('embedText', {'text': text});
      return vector?.cast<double>();
    } on PlatformException catch (e) {
      print('❌ Failed to embed text via native code: ${e.message}');
      return null;
    }
  }

  /// Calculates the cosine similarity between two vectors.
  /// This is a pure Dart implementation for efficiency, avoiding unnecessary native calls.
  double calculateSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.isEmpty || vec1.length != vec2.length) {
      throw ArgumentError('Vectors must be non-empty and of the same length.');
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
      norm1 += vec1[i] * vec1[i];
      norm2 += vec2[i] * vec2[i];
    }

    if (norm1 == 0 || norm2 == 0) {
      return 0.0;
    }

    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  /// Disposes of the native text embedder resources.
  Future<void> dispose() async {
    if (_isLoaded) {
      try {
        await _channel.invokeMethod('close');
        _isLoaded = false;
        print('🧹 Disposed native MediaPipe TextEmbedder.');
      } on PlatformException catch (e) {
        print('❌ Error disposing native MediaPipe: ${e.message}');
      }
    }
  }
}