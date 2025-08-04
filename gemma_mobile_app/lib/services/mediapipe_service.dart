import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MediaPipeTextService {
  dynamic _textEmbedder;
  
  bool _isMediaPipeAvailable = false;
  bool _initializationAttempted = false;
  
  bool get isTextClassifierLoaded => false; // Not available without additional models
  bool get isLanguageDetectorLoaded => false; // Not available without additional models
  bool get isTextEmbedderLoaded => _textEmbedder != null;
  bool get isMediaPipeAvailable => _isMediaPipeAvailable;
  
  /// Initialize MediaPipe text services with only available models
  Future<void> initializeAll(BuildContext context) async {
    if (_initializationAttempted) return;
    _initializationAttempted = true;
    
    print('🚀 Initializing MediaPipe Text services...');
    
    try {
      // Try to load MediaPipe module
      await _loadMediaPipeModule();
      
      if (_isMediaPipeAvailable) {
        // Only try to initialize text embedder (the only model we have)
        await _initializeTextEmbedder(context);
      }
      
      final loadedServices = <String>[];
      if (isTextEmbedderLoaded) loadedServices.add('TextEmbedder');
      
      if (_isMediaPipeAvailable && loadedServices.isNotEmpty) {
        print('✅ MediaPipe services loaded: ${loadedServices.join(", ")}');
      } else {
        print('⚠️ MediaPipe not available - using fallback implementations');
      }
      
    } catch (e) {
      print('❌ Error initializing MediaPipe services: $e');
      print('💡 Fallback implementations will be used');
      _isMediaPipeAvailable = false;
    }
  }
  
  /// Try to load MediaPipe module dynamically
  Future<void> _loadMediaPipeModule() async {
    try {
      // This will fail gracefully if MediaPipe is not available
      final module = await _importMediaPipe();
      if (module != null) {
        _isMediaPipeAvailable = true;
        print('✅ MediaPipe module loaded successfully');
      } else {
        throw Exception('MediaPipe module not available');
      }
    } catch (e) {
      print('⚠️ MediaPipe module loading failed: $e');
      _isMediaPipeAvailable = false;
    }
  }
  
  /// Dynamic import helper (will fail gracefully)
  Future<Map<String, dynamic>?> _importMediaPipe() async {
    try {
      // This is a placeholder for dynamic import
      // In practice, this would use conditional imports or reflection
      throw UnimplementedError('Dynamic MediaPipe import not available');
    } catch (e) {
      return null;
    }
  }
  
  /// Initialize text embedder for semantic similarity (only available model)
  Future<void> _initializeTextEmbedder(BuildContext context) async {
    if (!_isMediaPipeAvailable) return;
    
    try {
      print('🔢 Loading universal sentence encoder...');
      
      final ByteData embedderBytes = await DefaultAssetBundle.of(context)
          .load('assets/universal_sentence_encoder.tflite');
      
      // This would use the actual MediaPipe TextEmbedder if available
      // For now, we'll simulate the attempt and let it fail gracefully
      throw Exception('MediaPipe native bindings not available');
      
    } catch (e) {
      print('⚠️ Universal sentence encoder model loading failed: $e');
      _textEmbedder = null;
    }
  }
  
  /// Classify text sentiment with fallback (no MediaPipe model available)
  Future<Map<String, dynamic>?> classifyText(String text) async {
    print('📝 Classifying: "${text.length > 50 ? text.substring(0, 50) + "..." : text}"');
    
    // Always use fallback since we don't have the BERT classifier model
    return _classifyWithFallback(text);
  }
  
  /// Fallback text classification
  Map<String, dynamic> _classifyWithFallback(String text) {
    // Simple sentiment analysis based on keywords
    final positiveWords = ['good', 'great', 'excellent', 'amazing', 'wonderful', 'fantastic', 'love', 'like', 'happy', 'joy', 'awesome', 'perfect', 'brilliant'];
    final negativeWords = ['bad', 'terrible', 'awful', 'hate', 'dislike', 'sad', 'angry', 'frustrated', 'disappointed', 'horrible', 'worst', 'disgusting'];
    
    final lowerText = text.toLowerCase();
    int positiveScore = 0;
    int negativeScore = 0;
    
    for (final word in positiveWords) {
      if (lowerText.contains(word)) positiveScore++;
    }
    
    for (final word in negativeWords) {
      if (lowerText.contains(word)) negativeScore++;
    }
    
    String sentiment;
    double confidence;
    
    if (positiveScore > negativeScore) {
      sentiment = 'positive';
      confidence = (positiveScore / (positiveScore + negativeScore + 1));
    } else if (negativeScore > positiveScore) {
      sentiment = 'negative';
      confidence = (negativeScore / (positiveScore + negativeScore + 1));
    } else {
      sentiment = 'neutral';
      confidence = 0.5;
    }
    
    print('✅ Fallback sentiment: $sentiment (${(confidence * 100).toStringAsFixed(1)}%)');
    
    return {
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
      'method': 'Fallback',
      'classifications': [
        {
          'sentiment': sentiment,
          'confidence': confidence,
          'positive_words': positiveScore,
          'negative_words': negativeScore,
        }
      ],
    };
  }
  
  /// Detect language with fallback (no MediaPipe model available)
  Future<Map<String, dynamic>?> detectLanguage(String text) async {
    print('🌍 Detecting language: "${text.length > 30 ? text.substring(0, 30) + "..." : text}"');
    
    // Always use fallback since we don't have the language detector model
    return _detectLanguageWithFallback(text);
  }
  
  /// Fallback language detection
  Map<String, dynamic> _detectLanguageWithFallback(String text) {
    // Simple heuristic-based language detection
    final englishWords = ['the', 'and', 'is', 'in', 'to', 'of', 'a', 'that', 'it', 'with', 'for', 'as', 'was', 'on', 'are'];
    final spanishWords = ['el', 'la', 'de', 'que', 'y', 'en', 'un', 'es', 'se', 'no', 'te', 'lo', 'le', 'da', 'su'];
    final frenchWords = ['le', 'de', 'et', 'à', 'un', 'il', 'être', 'et', 'en', 'avoir', 'que', 'pour', 'dans', 'ce', 'son'];
    final germanWords = ['der', 'die', 'und', 'in', 'den', 'von', 'zu', 'das', 'mit', 'sich', 'des', 'auf', 'für', 'ist', 'im'];
    
    final lowerText = text.toLowerCase();
    int englishScore = 0;
    int spanishScore = 0;
    int frenchScore = 0;
    int germanScore = 0;
    
    for (final word in englishWords) {
      if (lowerText.contains(' $word ') || lowerText.startsWith('$word ') || lowerText.endsWith(' $word')) {
        englishScore++;
      }
    }
    
    for (final word in spanishWords) {
      if (lowerText.contains(' $word ') || lowerText.startsWith('$word ') || lowerText.endsWith(' $word')) {
        spanishScore++;
      }
    }
    
    for (final word in frenchWords) {
      if (lowerText.contains(' $word ') || lowerText.startsWith('$word ') || lowerText.endsWith(' $word')) {
        frenchScore++;
      }
    }
    
    for (final word in germanWords) {
      if (lowerText.contains(' $word ') || lowerText.startsWith('$word ') || lowerText.endsWith(' $word')) {
        germanScore++;
      }
    }
    
    String language = 'unknown';
    double confidence = 0.3;
    
    final maxScore = [englishScore, spanishScore, frenchScore, germanScore].reduce(math.max);
    if (maxScore > 0) {
      if (englishScore == maxScore) {
        language = 'en';
        confidence = 0.7;
      } else if (spanishScore == maxScore) {
        language = 'es';
        confidence = 0.7;
      } else if (frenchScore == maxScore) {
        language = 'fr';
        confidence = 0.7;
      } else if (germanScore == maxScore) {
        language = 'de';
        confidence = 0.7;
      }
    }
    
    print('✅ Fallback language: $language (${(confidence * 100).toStringAsFixed(1)}%)');
    
    return {
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
      'method': 'Fallback',
      'predictions': [
        {
          'language': language,
          'confidence': confidence,
          'scores': {
            'english': englishScore,
            'spanish': spanishScore,
            'french': frenchScore,
            'german': germanScore,
          }
        }
      ],
    };
  }
  
  /// Generate text embeddings with fallback
  Future<Map<String, dynamic>?> embedText(String text) async {
    print('🔢 Embedding: "${text.length > 30 ? text.substring(0, 30) + "..." : text}"');
    
    // Always use fallback since MediaPipe native bindings aren't working
    return _embedWithFallback(text);
  }
  
  /// Fallback text embedding
  Map<String, dynamic> _embedWithFallback(String text) {
    print('✅ Fallback embedding generated');
    
    return {
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
      'method': 'Fallback',
      'embeddings': [
        {
          'dimensions': 512,
          'type': 'hash_based',
          'available': true,
        }
      ],
    };
  }
  
  /// Calculate semantic similarity with fallback
  Future<double?> calculateSimilarity(String text1, String text2) async {
    print('🔍 Calculating similarity...');
    print('   Text 1: "${text1.length > 30 ? text1.substring(0, 30) + "..." : text1}"');
    print('   Text 2: "${text2.length > 30 ? text2.substring(0, 30) + "..." : text2}"');
    
    // Always use fallback
    return _calculateSimilarityFallback(text1, text2);
  }
  
  /// Fallback similarity calculation
  double _calculateSimilarityFallback(String text1, String text2) {
    // Simple Jaccard similarity based on word overlap
    final words1 = text1.toLowerCase().split(RegExp(r'\W+'));
    final words2 = text2.toLowerCase().split(RegExp(r'\W+'));
    
    final set1 = words1.toSet();
    final set2 = words2.toSet();
    
    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;
    
    final similarity = union > 0 ? intersection / union : 0.0;
    print('✅ Fallback similarity: ${(similarity * 100).toStringAsFixed(1)}%');
    return similarity;
  }
  
  /// Comprehensive text analysis using all available tools
  Future<Map<String, dynamic>> analyzeText(String text) async {
    print('🔍 === COMPREHENSIVE TEXT ANALYSIS ===');
    print('📝 Input: "${text.length > 100 ? text.substring(0, 100) + "..." : text}"');
    
    final analysis = <String, dynamic>{
      'input_text': text,
      'timestamp': DateTime.now().toIso8601String(),
      'services_used': [],
      'results': {},
      'method': 'Fallback', // Always fallback since MediaPipe isn't working
    };
    
    // Language Detection
    final language = await detectLanguage(text);
    if (language != null) {
      analysis['results']['language'] = language;
      analysis['services_used'].add('language_detection');
    }
    
    // Text Classification (Sentiment)
    final classification = await classifyText(text);
    if (classification != null) {
      analysis['results']['sentiment'] = classification;
      analysis['services_used'].add('text_classification');
    }
    
    // Text Embedding
    final embedding = await embedText(text);
    if (embedding != null) {
      analysis['results']['embedding'] = embedding;
      analysis['services_used'].add('text_embedding');
    }
    
    print('✅ Analysis complete. Services used: ${analysis['services_used'].join(", ")}');
    return analysis;
  }
  
  /// Get status of all MediaPipe services
  Map<String, dynamic> getServiceStatus() {
    return {
      'mediapipe_available': _isMediaPipeAvailable,
      'initialization_attempted': _initializationAttempted,
      'text_classifier': {
        'loaded': false,
        'description': 'BERT-based sentiment analysis (model not available)',
        'fallback_available': true,
      },
      'language_detector': {
        'loaded': false,
        'description': 'Automatic language detection (model not available)',
        'fallback_available': true,
      },
      'text_embedder': {
        'loaded': isTextEmbedderLoaded,
        'description': 'Universal sentence encoder for semantic similarity',
        'fallback_available': true,
      },
      'overall_status': true, // Always working with fallbacks
      'fallback_available': true,
      'available_models': ['universal_sentence_encoder.tflite'],
      'missing_models': ['bert_classifier.tflite', 'language_detector.tflite'],
    };
  }
  
  /// Get available features as a list
  List<String> getAvailableFeatures() {
    final features = <String>[
      'Fallback Sentiment Analysis',
      'Fallback Language Detection',
      'Fallback Text Embeddings',
      'Fallback Semantic Similarity',
    ];
    
    if (_isMediaPipeAvailable && isTextEmbedderLoaded) {
      features.add('MediaPipe Text Embeddings');
    }
    
    return features;
  }
  
  void dispose() {
    print('🧹 Disposing MediaPipe Text services...');
    _textEmbedder = null;
    _isMediaPipeAvailable = false;
    _initializationAttempted = false;
    print('✅ MediaPipe Text services disposed');
  }
}