import 'package:flutter/material.dart';
import 'package:ollama_chat/Pages/chat_page.dart';
import 'package:ollama_chat/Widgets/chat_app_bar.dart';
import 'package:ollama_chat/Widgets/chat_drawer.dart';

class OllamaChatMainPage extends StatelessWidget {
  const OllamaChatMainPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(title: title),
      body: const SafeArea(child: ChatPage()),
      drawer: const ChatDrawer(),
    );
  }
}
