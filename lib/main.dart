import 'package:flutter/material.dart';
import 'package:ollama_chat/Pages/main_page.dart';

void main() {
  runApp(const OllamaChatApp());
}

class OllamaChatApp extends StatelessWidget {
  const OllamaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ollama Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: WidgetsBinding.instance.window.platformBrightness,
        ),
        useMaterial3: true,
      ),
      home: const OllamaChatMainPage(title: 'Ollama Chat'),
    );
  }
}
