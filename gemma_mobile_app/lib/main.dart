import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/database/objectbox_store.dart';
import 'presentation/widgets/providers/chat_provider.dart';
import 'services/gemma_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ObjectBox database
  final objectBoxStore = await ObjectBoxStore.getInstance();
  
  // Initialize Gemma service
  final gemmaService = GemmaService();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ObjectBoxStore>.value(value: objectBoxStore),
        Provider<GemmaService>.value(value: gemmaService),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            gemmaService: gemmaService,
            objectBoxStore: objectBoxStore,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}