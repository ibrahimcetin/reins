import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:reins/Models/ollama_model.dart';
import 'package:reins/Pages/chat_page/subwidgets/chat_attachment_list_view.dart';
import 'package:reins/Providers/chat_provider.dart';
import 'package:reins/Widgets/chat_app_bar.dart';
import 'package:reins/Widgets/ollama_bottom_sheet_header.dart';
import 'package:reins/Widgets/selection_bottom_sheet.dart';
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

  // This is for the image attachment
  final List<File> _imageFiles = [];

  // Text field controller for the chat prompt
  final _textFieldController = TextEditingController();
  bool get _isTextFieldHasText => _textFieldController.text.trim().isNotEmpty;

  // These are for the welcome screen animation
  var _crossFadeState = CrossFadeState.showFirst;
  double _scale = 1.0;

  // This is for the exit request listener
  late final AppLifecycleListener _appLifecycleListener;

  @override
  void initState() {
    super.initState();

    // If the server address changes, reset the selected model
    Hive.box('settings').watch(key: 'serverAddress').listen((event) {
      _selectedModel = null;
    });

    // Listen exit request to delete the unused attached images
    _appLifecycleListener = AppLifecycleListener(onExitRequested: () async {
      for (final imageFile in _imageFiles) {
        await imageFile.delete();
      }
      return AppExitResponse.exit;
    });
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (BuildContext context, ChatProvider chatProvider, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!ResponsiveBreakpoints.of(context).isMobile)
              ChatAppBar(), // If the screen is large, show the app bar
            Expanded(
              child: _buildChatBody(chatProvider),
            ),
            if (_imageFiles.isNotEmpty)
              SizedBox(
                height: 100,
                child: ChatAttachmentListView(
                  imageFiles: _imageFiles,
                  onRemove: _handleImageRemove,
                ),
              ),
            // TODO: Wrap with ConstrainedBox to limit the height
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ChatTextField(
                key: ValueKey(chatProvider.currentChat?.id),
                controller: _textFieldController,
                onChanged: (_) => setState(() {}),
                onEditingComplete: () => _handleOnEditingComplete(chatProvider),
                prefixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _handleAttachmentButton,
                ),
                suffixIcon: _buildTextFieldSuffixIcon(chatProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatBody(ChatProvider chatProvider) {
    if (chatProvider.messages.isEmpty) {
      if (chatProvider.currentChat == null) {
        if (Hive.box('settings').get('serverAddress') == null) {
          return ChatEmpty(
            child: ChatWelcome(
              showingState: _crossFadeState,
              onFirstChildFinished: () =>
                  setState(() => _crossFadeState = CrossFadeState.showSecond),
              secondChildScale: _scale,
              onSecondChildScaleEnd: () => setState(() => _scale = 1.0),
            ),
          );
        } else {
          return ChatEmpty(
            child: ChatSelectModelButton(
              currentModelName: _selectedModel?.name,
              onPressed: () => _showModelSelectionBottomSheet(context),
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
        key: ValueKey(chatProvider.currentChat?.id),
        messages: chatProvider.messages,
        isAwaitingReply: chatProvider.isCurrentChatThinking,
        error: chatProvider.currentChatError != null
            ? ChatError(
                message: chatProvider.currentChatError!.message,
                onRetry: () => chatProvider.retryLastPrompt(),
              )
            : null,
      );
    }
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
    } else if (_isTextFieldHasText) {
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

        chatProvider.sendPrompt(
          _textFieldController.text,
          images: _imageFiles.toList(),
        );

        setState(() {
          _textFieldController.clear();
          _imageFiles.clear();
        });
      }
    } else {
      chatProvider.sendPrompt(
        _textFieldController.text,
        images: _imageFiles.toList(),
      );

      setState(() {
        _textFieldController.clear();
        _imageFiles.clear();
      });
    }
  }

  Future<void> _handleOnEditingComplete(ChatProvider chatProvider) async {
    if (_isTextFieldHasText && chatProvider.isCurrentChatStreaming == false) {
      await _handleSendButton(chatProvider);
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

  Future<void> _handleAttachmentButton() async {
    final picker = ImagePicker();
    final sPickedImage = await picker.pickImage(source: ImageSource.gallery);
    // await picker.pickMultiImage(limit: 4);
    final pickedImages = sPickedImage == null ? [] : [sPickedImage];

    if (pickedImages.isEmpty) return;

    // Create images directory if it doesn't exist
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final imagesPath = path.join(documentsDirectory.path, 'images');
    await Directory(imagesPath).create(recursive: true);

    // Compress and save the images
    var imageFiles = <File>[];
    for (final image in pickedImages) {
      final imageFilePath = path.join(
        imagesPath,
        '${DateTime.now().microsecondsSinceEpoch}${path.extension(image.path)}',
      );

      final imageFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        imageFilePath,
        quality: 10,
      );

      // Add an empty path if the image could not be compressed to show error
      imageFiles.add(File(imageFile?.path ?? ''));
    }

    setState(() => _imageFiles.addAll(imageFiles));
  }

  Future<void> _handleImageRemove(File imageFile) async {
    await imageFile.delete();
    setState(() => _imageFiles.remove(imageFile));
  }
}
