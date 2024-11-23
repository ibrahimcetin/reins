import 'package:flutter/material.dart';
import 'package:ollama_chat/Pages/chat_page/chat_page.dart';
import 'package:ollama_chat/Widgets/chat_app_bar.dart';
import 'package:ollama_chat/Widgets/chat_drawer.dart';
import 'package:responsive_framework/responsive_framework.dart';

class OllamaChatMainPage extends StatelessWidget {
  const OllamaChatMainPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      return Scaffold(
        appBar: ChatAppBar(title: title),
        body: const SafeArea(child: ChatPage()),
        drawer: const ChatDrawer(),
      );
    } else {
      return _OllamaChatLargeMainPage(title: title);
    }
  }
}

class _OllamaChatLargeMainPage extends StatelessWidget {
  const _OllamaChatLargeMainPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            const ChatDrawer(),
            Expanded(child: ChatPage()),
          ],
        ),
      ),
    );
  }
}
