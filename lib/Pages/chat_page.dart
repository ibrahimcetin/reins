import 'package:flutter/material.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:ollama_chat/Models/ollama_model.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:ollama_chat/Widgets/chat_bubble.dart';
import 'package:ollama_chat/Widgets/selection_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // This is for empty chat state to select a model
  OllamaModel? _selectedModel;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (BuildContext context, ChatProvider chatProvider, _) {
        final messages = _getMessages(chatProvider);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyChatState(context)
                  : ListView.builder(
                      key: ObjectKey(chatProvider.currentChat?.id),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - index - 1];

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
                  suffixIcon: _buildTextFieldSuffixIcon(chatProvider),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildTextFieldSuffixIcon(ChatProvider chatProvider) {
    if (chatProvider.isCurrentChatStreaming) {
      return IconButton(
        icon: const Icon(Icons.stop_rounded),
        onPressed: () {
          chatProvider.cancelCurrentStreaming();
        },
        color: Theme.of(context).colorScheme.onSurface,
      );
    } else if (chatProvider.textFieldController.text.trim().isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.arrow_upward_rounded),
        onPressed: () async {
          if (chatProvider.currentChat == null) {
            if (_selectedModel == null) {
              await _showChatLLMBottomSheet(context);
            }

            if (_selectedModel != null) {
              await chatProvider.createNewChat(_selectedModel!);
              chatProvider.sendUserPrompt();
            }
          } else {
            chatProvider.sendUserPrompt();
          }
        },
        color: Theme.of(context).colorScheme.onSurface,
      );
    } else {
      return null;
    }
  }

  // ? Is this a good solution to show Thinking... message?
  bool _isOllamaThinking(ChatProvider chatProvider) {
    return chatProvider.isCurrentChatStreaming &&
        chatProvider.messages.isNotEmpty &&
        chatProvider.messages.last.role != OllamaMessageRole.assistant;
  }

  List<OllamaMessage> _getMessages(ChatProvider chatProvider) {
    if (_isOllamaThinking(chatProvider)) {
      var messages = [...chatProvider.messages];

      messages.add(
        OllamaMessage("Thinking...", role: OllamaMessageRole.assistant),
      );

      return messages;
    } else {
      return chatProvider.messages;
    }
  }

  Widget _buildEmptyChatState(BuildContext context) {
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
          label: Text(_selectedModel?.name ?? 'Select a model to start'),
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
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);

        return SelectionBottomSheet(
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset("assets/images/ollama.png", height: 48),
                ),
              ),
              const Text(
                "Select a LLM Model",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          fetchItems: chatProvider.fetchAvailableModels,
          currentSelection: _selectedModel,
          onSelection: (selectedModel) {
            setState(() {
              _selectedModel = selectedModel;
            });
          },
        );
      },
      isDismissible: false,
      enableDrag: false,
    );
  }
}
