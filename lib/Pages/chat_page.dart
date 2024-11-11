import 'package:flutter/material.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:ollama_chat/Services/ollama_service.dart';
import 'package:ollama_chat/Widgets/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<OllamaMessage> _messages = [];
  final _textFieldController = TextEditingController();
  final _scrollController = ScrollController();

  final service = OllamaService(model: "llama3.2-vision:latest");

  @override
  void dispose() {
    _textFieldController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];

              return ChatBubble(message: message);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              labelText: 'Prompt',
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_upward),
                onPressed: _sendPrompt,
              ),
            ),
            maxLines: null,
          ),
        ),
      ],
    );
  }

  Future<void> _sendPrompt() async {
    final userMessage = OllamaMessage(
      _textFieldController.text.trim(),
      role: OllamaMessageRole.user,
    );

    setState(() {
      _textFieldController.clear();
      _messages.add(userMessage);
    });

    _scrollToBottom();

    final ollamaMessage = await service.chat(_messages);

    setState(() {
      _messages.add(ollamaMessage);
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    // If the scroll position is not at the bottom, do not scroll.
    // This is to prevent the scroll position from changing when the user
    // is reading previous messages.
    if (_scrollController.position.pixels !=
            _scrollController.position.maxScrollExtent &&
        _messages.last.role != OllamaMessageRole.user) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
  }
}
