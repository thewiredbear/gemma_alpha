import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/database/objectbox_store.dart';
import 'presentation/widgets/providers/chat_provider.dart';
import 'services/gemma_services.dart';
import 'services/text_embedder_service.dart';
import 'services/rag_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ObjectBox database
  final objectBoxStore = await ObjectBoxStore.getInstance();
  
  // Initialize RAG service
  final ragService = await RagService.getInstance(objectBoxStore);
  await ragService.ensureDbInitialized();
  
  // Initialize services
  final gemmaService = GemmaService();
  final textEmbedderService = TextEmbedderService();
  
  // Initialize text embedder service early to avoid runtime errors
  // Note: This will use fallback embeddings if the TFLite model is not available
  print('🔧 Pre-initializing text embedder service...');
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ObjectBoxStore>.value(value: objectBoxStore),
        Provider<GemmaService>.value(value: gemmaService),
        Provider<TextEmbedderService>.value(value: textEmbedderService),
        Provider<RagService>.value(value: ragService),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            gemmaService: gemmaService,
            objectBoxStore: objectBoxStore,
            ragService: ragService,
            textEmbedderService: textEmbedderService,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}