import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:ollama_chat/Models/ollama_model.dart';
import 'package:ollama_chat/Models/settings_route_arguments.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:ollama_chat/Widgets/chat_bubble.dart';
import 'package:ollama_chat/Widgets/ollama_bottom_sheet_header.dart';
import 'package:ollama_chat/Widgets/selection_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // This is for empty chat state to select a model
  OllamaModel? _selectedModel;

  var _crossFadeState = CrossFadeState.showFirst;
  double _scale = 1.0;

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
                  : _ChatListView(
                      key: ValueKey(chatProvider.currentChat?.id),
                      messages: messages,
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
                onTapOutside: (PointerDownEvent event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
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
        color: Theme.of(context).colorScheme.onSurface,
        onPressed: () async {
          if (Hive.box('settings').get('serverAddress') == null) {
            setState(() => _scale = _scale == 1.0 ? 1.05 : 1.0);
          } else if (chatProvider.currentChat == null) {
            if (_selectedModel == null) {
              await _showModelSelectionBottomSheet(context);
            }

            if (_selectedModel != null) {
              await chatProvider.createNewChat(_selectedModel!);
              chatProvider.sendUserPrompt();
            }
          } else {
            chatProvider.sendUserPrompt();
          }
        },
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

  // TODO: Refactor this method to a separate widget.
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
        if (Hive.box('settings').get('serverAddress') != null)
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(_selectedModel?.name ?? 'Select a model to start'),
            iconAlignment: IconAlignment.end,
            onPressed: () {
              _showModelSelectionBottomSheet(context);
            },
          )
        else
          AnimatedCrossFade(
            crossFadeState: _crossFadeState,
            duration: const Duration(milliseconds: 150),
            firstChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'Welcome to Ollama Chat!',
                    speed: const Duration(milliseconds: 100),
                  ),
                  TyperAnimatedText(
                    'Configure the server address to start.',
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                isRepeatingAnimation: false,
                pause: Duration(milliseconds: 1500),
                onFinished: () =>
                    setState(() => _crossFadeState = CrossFadeState.showSecond),
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 100),
                onEnd: () => setState(() => _scale = 1.0),
                child: OutlinedButton.icon(
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                  ),
                  label: Text('Tap to configure the server address'),
                  iconAlignment: IconAlignment.start,
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/settings',
                      arguments:
                          SettingsRouteArguments(autoFocusServerAddress: true),
                    );
                  },
                ),
              ),
            ),
            layoutBuilder:
                (topChild, topChildKey, bottomChild, bottomChildKey) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    key: topChildKey,
                    child: topChild,
                  ),
                  Positioned(
                    key: bottomChildKey,
                    child: bottomChild,
                  ),
                ],
              );
            },
          ),
      ],
    );
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

class _ChatListView extends StatefulWidget {
  final List<OllamaMessage> messages;

  const _ChatListView({super.key, required this.messages});

  @override
  State<_ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<_ChatListView> {
  static final _scrollOffsetBucket = PageStorageBucket();

  late final ScrollController _scrollController;
  bool _isScrollToBottomButtonVisible = false;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController(
      initialScrollOffset: _readScrollOffset(),
    );

    // We need to wait to _scrollController to be attached to the list view
    // to be able to get its position and update the visibility of the scroll to bottom button.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollToBottomButtonVisibility();
    });

    _scrollController.addListener(() {
      _writeScrollOffset();

      _updateScrollToBottomButtonVisibility();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ListView.builder(
          key: widget.key,
          controller: _scrollController,
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            final message = widget.messages[widget.messages.length - index - 1];

            return ChatBubble(message: message);
          },
          reverse: true,
        ),
        if (_isScrollToBottomButtonVisible)
          IconButton(
            onPressed: _scrollToBottom,
            icon: const Icon(Icons.arrow_downward_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
      ],
    );
  }

  void _updateScrollToBottomButtonVisibility() {
    if (_scrollController.position.pixels > 100 &&
        !_isScrollToBottomButtonVisible) {
      setState(() {
        _isScrollToBottomButtonVisible = true;
      });
    }

    if (_scrollController.position.pixels < 100 &&
        _isScrollToBottomButtonVisible) {
      setState(() {
        _isScrollToBottomButtonVisible = false;
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  double _readScrollOffset() {
    return _scrollOffsetBucket.readState(context, identifier: widget.key) ??
        0.0;
  }

  void _writeScrollOffset() {
    _scrollOffsetBucket.writeState(
      context,
      _scrollController.offset,
      identifier: widget.key,
    );
  }
}
