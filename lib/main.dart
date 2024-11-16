import 'package:flutter/material.dart';
import 'package:ollama_chat/Pages/main_page.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('settings');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: const OllamaChatApp(),
    ),
  );
}

class OllamaChatApp extends StatelessWidget {
  const OllamaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ollama Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: View.of(context).platformDispatcher.platformBrightness,
          dynamicSchemeVariant: DynamicSchemeVariant.neutral,
        ),
        useMaterial3: true,
      ),
      home: const OllamaChatMainPage(title: 'Ollama Chat'),
    );
  }
}
