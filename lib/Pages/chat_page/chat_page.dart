import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:reins/Constants/constants.dart';
import 'package:reins/Models/chat_preset.dart';
import 'package:reins/Models/ollama_model.dart';
import 'package:reins/Providers/chat_provider.dart';
import 'package:reins/Widgets/chat_app_bar.dart';
import 'package:reins/Widgets/ollama_bottom_sheet_header.dart';
import 'package:reins/Widgets/selection_bottom_sheet.dart';
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

  // This is for the chat presets
  List<ChatPreset> _presets = ChatPresets.randomPresets;

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
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  _buildChatBody(chatProvider),
                  _buildChatFooter(chatProvider),
                ],
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
        key: PageStorageKey<String>(chatProvider.currentChat?.id ?? 'empty'),
        messages: chatProvider.messages,
        isAwaitingReply: chatProvider.isCurrentChatThinking,
        error: chatProvider.currentChatError != null
            ? ChatError(
                message: chatProvider.currentChatError!.message,
                onRetry: () => chatProvider.retryLastPrompt(),
              )
            : null,
        bottomPadding: _imageFiles.isNotEmpty
            ? MediaQuery.of(context).size.height * 0.15
            : null, // TODO: Calculate the height of attachments row
      );
    }
  }

  Widget _buildChatFooter(ChatProvider chatProvider) {
    if (_imageFiles.isNotEmpty) {
      return ChatAttachmentRow(
        itemCount: _imageFiles.length,
        itemBuilder: (context, index) {
          return ChatAttachmentImage(
            imageFile: _imageFiles[index],
            onRemove: _handleImageRemove,
          );
        },
      );
    } else if (chatProvider.messages.isEmpty) {
      return ChatAttachmentRow(
        itemCount: _presets.length,
        itemBuilder: (context, index) {
          final preset = _presets[index];
          return ChatAttachmentPreset(
            preset: preset,
            onPressed: () async {
              setState(() => _textFieldController.text = preset.prompt);
              await _handleSendButton(chatProvider);
            },
          );
        },
      );
    } else {
      return const SizedBox();
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

        chatProvider.generateTitleForCurrentChat();

        setState(() {
          _textFieldController.clear();
          _imageFiles.clear();
          _presets = ChatPresets.randomPresets;
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
    if (Platform.isIOS) {
      final photosPermission = await Permission.photos
          .onDeniedCallback(_showPhotosDeniedAlert)
          .onPermanentlyDeniedCallback(_showPhotosDeniedAlert)
          .request();
      if (!photosPermission.isGranted && !photosPermission.isLimited) return;
    }

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

  Future<void> _handleImageRemove(File imageFile) async {
    await imageFile.delete();
    setState(() => _imageFiles.remove(imageFile));
  }
}
