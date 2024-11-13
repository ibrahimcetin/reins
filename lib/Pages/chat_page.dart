import 'package:flutter/material.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:ollama_chat/Widgets/chat_bubble.dart';
import 'package:ollama_chat/Widgets/chat_model_selection_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _llmModel;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (BuildContext context, ChatProvider chatProvider, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: chatProvider.messages.isEmpty
                  ? _ollamaChatLogo(context)
                  : ListView.builder(
                      reverse: true,
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatProvider
                            .messages[chatProvider.messages.length - index - 1];

                        return ChatBubble(message: message);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: chatProvider.textFieldController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  labelText: 'Prompt',
                  suffixIcon:
                      chatProvider.textFieldController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: () async {
                                if (chatProvider.chat == null) {
                                  if (_llmModel == null) {
                                    await _showChatLLMBottomSheet(context);
                                  }

                                  if (_llmModel != null) {
                                    await chatProvider.createChat(_llmModel!);
                                    chatProvider.sendUserPrompt();
                                  }
                                } else {
                                  chatProvider.sendUserPrompt();
                                }
                              },
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                ),
                maxLines: null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ollamaChatLogo(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          "assets/images/ollama.svg",
          height: 48,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text(_llmModel ?? 'Select a model to start'),
          iconAlignment: IconAlignment.end,
          onPressed: () {
            _showChatLLMBottomSheet(context);
          },
        ),
      ],
    );
  }

  Future _showChatLLMBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return ChatModelSelectionBottomSheet(
          title: "Select a LLM Model",
          values: const [
            "llama3.2:latest",
            "llama3.2-vision:latest",
          ],
          currentSelection: _llmModel,
          onSelection: (selectedModel) {
            setState(() {
              _llmModel = selectedModel;
            });
          },
        );
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.0),
          topRight: Radius.circular(28.0),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      isDismissible: false,
    );
  }
}
