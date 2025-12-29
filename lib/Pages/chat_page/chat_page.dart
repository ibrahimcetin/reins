import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:reins/Widgets/chat_app_bar.dart';
import 'package:reins/Widgets/ollama_bottom_sheet_header.dart';
import 'package:reins/Widgets/selection_bottom_sheet.dart';

import 'chat_page_view_model.dart';
import 'subwidgets/subwidgets.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // ViewModel reference
  late final ChatPageViewModel _viewModel;

  // Welcome screen animation state
  var _crossFadeState = CrossFadeState.showFirst;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ChatPageViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to ViewModel changes
    context.watch<ChatPageViewModel>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (!ResponsiveBreakpoints.of(context).isMobile) ChatAppBar(), // If the screen is large, show the app bar
        Expanded(
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              _buildChatBody(),
              _buildChatFooter(),
            ],
          ),
        ),
        // TODO: Wrap with ConstrainedBox to limit the height
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ChatTextField(
            key: ValueKey(_viewModel.currentChat?.id),
            controller: _viewModel.textFieldController,
            onEditingComplete: _sendMessage,
            prefixIcon: IconButton(
              icon: Icon(Icons.add),
              onPressed: _handleAttachmentButton,
            ),
            suffixIcon: _buildTextFieldSuffixIcon(),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBody() {
    if (_viewModel.messages.isEmpty) {
      if (_viewModel.currentChat == null) {
        if (!_viewModel.isServerConfigured) {
          return ChatEmpty(
            child: ChatWelcome(
              showingState: _crossFadeState,
              onFirstChildFinished: () => setState(() => _crossFadeState = CrossFadeState.showSecond),
              secondChildScale: _scale,
              onSecondChildScaleEnd: () => setState(() => _scale = 1.0),
            ),
          );
        } else {
          return ChatEmpty(
            child: ChatSelectModelButton(
              currentModelName: _viewModel.selectedModel?.name,
              onPressed: _showModelSelectionBottomSheet,
            ),
          );
        }
      } else {
        return ChatEmpty(
          child: Text('No messages yet!'),
        );
      }
    } else {
      return ChatListView(
        key: PageStorageKey<String>(_viewModel.currentChat?.id ?? 'empty'),
        messages: _viewModel.messages,
        isAwaitingReply: _viewModel.isThinking,
        error: _viewModel.currentError != null
            ? ChatError(
                message: _viewModel.currentError!.message,
                onRetry: () => _viewModel.retryLastPrompt(),
              )
            : null,
        bottomPadding: _viewModel.hasImageAttachments
            ? MediaQuery.of(context).size.height * 0.15
            : null, // TODO: Calculate the height of attachments row
      );
    }
  }

  Widget _buildChatFooter() {
    if (_viewModel.hasImageAttachments) {
      return ChatAttachmentRow(
        itemCount: _viewModel.imageFiles.length,
        itemBuilder: (context, index) {
          return ChatAttachmentImage(
            imageFile: _viewModel.imageFiles[index],
            onRemove: (imageFile) => _viewModel.removeImage(imageFile),
          );
        },
      );
    } else if (_viewModel.messages.isEmpty) {
      return ChatAttachmentRow(
        itemCount: _viewModel.presets.length,
        itemBuilder: (context, index) {
          final preset = _viewModel.presets[index];
          return ChatAttachmentPreset(
            preset: preset,
            onPressed: () async {
              _viewModel.setTextFieldValue(preset.prompt);
              await _sendMessage();
            },
          );
        },
      );
    } else {
      return const SizedBox();
    }
  }

  Widget? _buildTextFieldSuffixIcon() {
    if (_viewModel.isStreaming) {
      return IconButton(
        icon: const Icon(Icons.stop_rounded),
        color: Theme.of(context).colorScheme.onSurface,
        onPressed: _viewModel.cancelStreaming,
      );
    } else if (_viewModel.hasText) {
      return IconButton(
        icon: const Icon(Icons.arrow_upward_rounded),
        color: Theme.of(context).colorScheme.onSurface,
        onPressed: _sendMessage,
      );
    } else {
      return null;
    }
  }

  Future<void> _sendMessage() async {
    await _viewModel.sendMessage(
      onModelSelectionRequired: _showModelSelectionBottomSheet,
      onServerNotConfigured: _onServerNotConfigured,
    );
  }

  Future<void> _showModelSelectionBottomSheet() async {
    final selectedModel = await showSelectionBottomSheet(
      key: ValueKey(Hive.box('settings').get('serverAddress')),
      context: context,
      header: OllamaBottomSheetHeader(title: "Select a LLM Model"),
      fetchItems: _viewModel.fetchAvailableModels,
      currentSelection: _viewModel.selectedModel,
    );

    _viewModel.setSelectedModel(selectedModel);
  }

  Future<void> _handleAttachmentButton() async {
    await _viewModel.pickImages(
      onPermissionDenied: _showPhotosDeniedAlert,
    );
  }

  void _onServerNotConfigured() {
    setState(() {
      _crossFadeState = CrossFadeState.showSecond;
      _scale = _scale == 1.0 ? 1.05 : 1.0;
    });
  }

  Future<void> _showPhotosDeniedAlert() async {
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Photos Permission Denied'),
          content: const Text('Please allow access to photos in the settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
