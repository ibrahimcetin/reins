import 'package:ollama_chat/Models/ollama_chat.dart';

class ChatConfigureArguments {
  String? systemPrompt;
  OllamaChatOptions chatOptions;

  ChatConfigureArguments({
    required this.systemPrompt,
    required this.chatOptions,
  });

  static get defaultArguments => ChatConfigureArguments(
        systemPrompt: null,
        chatOptions: OllamaChatOptions(),
      );
}
