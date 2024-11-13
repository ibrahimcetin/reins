import 'package:flutter/material.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:ollama_chat/Widgets/chat_bubble.dart';
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
        return ChatModelBottomSheet(
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
    );
  }
}

class ChatModelBottomSheet extends StatefulWidget {
  final Function(String) onSelection;

  const ChatModelBottomSheet({super.key, required this.onSelection});

  @override
  State<ChatModelBottomSheet> createState() => _ChatModelBottomSheetState();
}

class _ChatModelBottomSheetState extends State<ChatModelBottomSheet> {
  String? _llmModel;

  final List<String> _llmModels = [
    "llama3.2:latest",
    "llama3.2-vision:latest",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      "assets/images/ollama.png",
                      height: 48,
                    ),
                  ),
                ),
                const Text(
                  'Select a LLM Model',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  ..._llmModels.map((model) {
                    return RadioListTile(
                      title: Text(model),
                      value: model,
                      groupValue: _llmModel,
                      onChanged: (value) {
                        setState(() {
                          _llmModel = value;
                        });
                      },
                      secondary: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.info_outline),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (_llmModel != null) {
                      widget.onSelection(_llmModel!);
                      Navigator.of(context).pop();
                    } else {
                      // Do nothing
                    }
                  },
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
