import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/chat_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemma AI Chat',
      theme: AppTheme.darkTheme,
      home: const ChatPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}