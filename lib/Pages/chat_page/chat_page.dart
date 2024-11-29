import 'package:flutter/material.dart';
import 'package:ollama_chat/Models/ollama_model.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:ollama_chat/Widgets/chat_app_bar.dart';
import 'package:ollama_chat/Widgets/ollama_bottom_sheet_header.dart';
import 'package:ollama_chat/Widgets/selection_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'subwidgets/subwidgets.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // This is for empty chat state to select a model
  OllamaModel? _selectedModel;

  // Text field controller for the chat prompt
  final _textFieldController = TextEditingController();

  // These are for the welcome screen animation
  var _crossFadeState = CrossFadeState.showFirst;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();

    // If the server address changes, reset the selected model
    Hive.box('settings').watch(key: 'serverAddress').listen((event) {
      _selectedModel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (BuildContext context, ChatProvider chatProvider, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!ResponsiveBreakpoints.of(context).isMobile)
              ChatAppBar(title: 'Ollama Chat'),
            Expanded(
              child: chatProvider.messages.isEmpty
                  ? ChatEmpty(
                      child: (Hive.box('settings').get('serverAddress') != null)
                          ? ChatSelectModelButton(
                              currentModelName: _selectedModel?.name,
                              onPressed: () =>
                                  _showModelSelectionBottomSheet(context),
                            )
                          : ChatWelcome(
                              showingState: _crossFadeState,
                              onFirstChildFinished: () => setState(() =>
                                  _crossFadeState = CrossFadeState.showSecond),
                              secondChildScale: _scale,
                              onSecondChildScaleEnd: () =>
                                  setState(() => _scale = 1.0),
                            ),
                    )
                  : ChatListView(
                      key: ValueKey(chatProvider.currentChat?.id),
                      messages: chatProvider.messages,
                      isAwaitingReply: chatProvider.isCurrentChatThinking,
                      error: chatProvider.currentChatError != null
                          ? ChatError(
                              message: chatProvider.currentChatError!.message,
                              onRetry: () => chatProvider.retryLastPrompt(),
                            )
                          : null,
                    ),
            ),
            // TODO: Wrap with ConstrainedBox to limit the height
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ChatTextField(
                key: ValueKey(chatProvider.currentChat?.id),
                controller: _textFieldController,
                onChanged: (_) => setState(() {}),
                suffixIcon: _buildTextFieldSuffixIcon(chatProvider),
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
        color: Theme.of(context).colorScheme.onSurface,
        onPressed: () {
          chatProvider.cancelCurrentStreaming();
        },
      );
    } else if (_textFieldController.text.trim().isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.arrow_upward_rounded),
        color: Theme.of(context).colorScheme.onSurface,
        onPressed: () async {
          await _handleSendButton(chatProvider);
        },
      );
    } else {
      return null;
    }
  }

  Future<void> _handleSendButton(ChatProvider chatProvider) async {
    if (Hive.box('settings').get('serverAddress') == null) {
      setState(() => _crossFadeState = CrossFadeState.showSecond);
      setState(() => _scale = _scale == 1.0 ? 1.05 : 1.0);
    } else if (chatProvider.currentChat == null) {
      if (_selectedModel == null) {
        await _showModelSelectionBottomSheet(context);
      }

      if (_selectedModel != null) {
        await chatProvider.createNewChat(_selectedModel!);

        chatProvider.sendPrompt(_textFieldController.text);
        _textFieldController.clear();
      }
    } else {
      chatProvider.sendPrompt(_textFieldController.text);
      _textFieldController.clear();
    }
  }

  Future<void> _showModelSelectionBottomSheet(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final selectedModel = await showSelectionBottomSheet(
      key: ValueKey(Hive.box('settings').get('serverAddress')),
      context: context,
      header: OllamaBottomSheetHeader(title: "Select a LLM Model"),
      fetchItems: chatProvider.fetchAvailableModels,
      currentSelection: _selectedModel,
    );

    setState(() {
      _selectedModel = selectedModel;
    });
  }
}