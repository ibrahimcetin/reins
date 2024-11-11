import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ollama_chat/Pages/chat_page.dart';

class OllamaChatMainPage extends StatelessWidget {
  const OllamaChatMainPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          title,
          style: GoogleFonts.ubuntu(),
        ),
      ),
      body: const SafeArea(child: ChatPage()),
    );
  }
}
