import 'package:flutter/material.dart';
import 'package:ollama_chat/Pages/chat_page/chat_page.dart';
import 'package:ollama_chat/Widgets/chat_app_bar.dart';
import 'package:ollama_chat/Widgets/chat_drawer.dart';
import 'package:responsive_framework/responsive_framework.dart';

class OllamaChatMainPage extends StatelessWidget {
  const OllamaChatMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      return const Scaffold(
        appBar: ChatAppBar(),
        body: SafeArea(child: ChatPage()),
        drawer: ChatDrawer(),
      );
    } else {
      return _OllamaChatLargeMainPage();
    }
  }
}

class _OllamaChatLargeMainPage extends StatelessWidget {
  const _OllamaChatLargeMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            ChatDrawer(),
            Expanded(child: ChatPage()),
          ],
        ),
      ),
    );
  }
}
