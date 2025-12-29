import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:reins/Constants/constants.dart';
import 'package:reins/Models/chat_preset.dart';
import 'package:reins/Models/ollama_chat.dart';
import 'package:reins/Models/ollama_exception.dart';
import 'package:reins/Models/ollama_message.dart';
import 'package:reins/Models/ollama_model.dart';
import 'package:reins/Providers/chat_provider.dart';
import 'package:reins/Services/services.dart';

class ChatPageViewModel extends ChangeNotifier {
  final ChatProvider _chatProvider;
  final PermissionService _permissionService;
  final ImageService _imageService;

  ChatPageViewModel({
    required ChatProvider chatProvider,
    required PermissionService permissionService,
    required ImageService imageService,
  })  : _chatProvider = chatProvider,
        _permissionService = permissionService,
        _imageService = imageService {
    _initialize();
  }

  // ============================================================
  // Page State
  // ============================================================

  /// The selected model for new chats
  OllamaModel? _selectedModel;
  OllamaModel? get selectedModel => _selectedModel;

  /// The list of chat presets
  List<ChatPreset> _presets = ChatPresets.randomPresets;
  List<ChatPreset> get presets => _presets;

  /// The text field controller
  final TextEditingController textFieldController = TextEditingController();

  /// Whether the text field has text
  bool get hasText => textFieldController.text.trim().isNotEmpty;

  /// The app lifecycle listener for cleanup
  late final AppLifecycleListener _appLifecycleListener;

  /// The Hive settings subscription
  late final StreamSubscription _settingsSubscription;

  bool get isServerConfigured {
    return Hive.box('settings').get('serverAddress') != null;
  }

  // ============================================================
  // Initialization
  // ============================================================

  void _initialize() {
    // Listen to ChatProvider changes and forward notifications
    _chatProvider.addListener(_onChatProviderChanged);

    // Listen to text field changes to update UI (e.g., send button visibility)
    textFieldController.addListener(_onTextFieldChanged);

    // If the server address changes, reset the selected model
    _settingsSubscription = Hive.box('settings').watch(key: 'serverAddress').listen((event) {
      _selectedModel = null;
      notifyListeners();
    });

    // Listen for app exit to delete unused attached images
    _appLifecycleListener = AppLifecycleListener(onExitRequested: () async {
      await _imageService.deleteImages(imageFiles);
      return AppExitResponse.exit;
    });
  }

  void _onChatProviderChanged() {
    notifyListeners();
  }

  void _onTextFieldChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _chatProvider.removeListener(_onChatProviderChanged);
    textFieldController.removeListener(_onTextFieldChanged);
    textFieldController.dispose();
    _appLifecycleListener.dispose();
    _settingsSubscription.cancel();
    super.dispose();
  }

  // ============================================================
  // ChatProvider State (Proxied)
  // ============================================================

  /// The list of messages in the current chat
  List<OllamaMessage> get messages => _chatProvider.messages;

  /// The current chat
  OllamaChat? get currentChat => _chatProvider.currentChat;

  /// Whether the current chat is streaming a response
  bool get isStreaming => _chatProvider.isCurrentChatStreaming;

  /// Whether the current chat is thinking (waiting for response)
  bool get isThinking => _chatProvider.isCurrentChatThinking;

  /// The current chat error, if any
  OllamaException? get currentError => _chatProvider.currentChatError;

  // ============================================================
  // ChatProvider Actions (Delegated)
  // ============================================================

  /// Cancels the current streaming response
  void cancelStreaming() {
    _chatProvider.cancelCurrentStreaming();
  }

  /// Retries the last prompt
  Future<void> retryLastPrompt() async {
    await _chatProvider.retryLastPrompt();
  }

  /// Fetches available models from the server
  Future<List<OllamaModel>> fetchAvailableModels() async {
    return await _chatProvider.fetchAvailableModels();
  }

  // ============================================================
  // Model Selection
  // ============================================================

  /// Sets the selected model
  void setSelectedModel(OllamaModel? model) {
    _selectedModel = model;
    notifyListeners();
  }

  // ============================================================
  // Text Field
  // ============================================================

  /// Sets the text field value (e.g., for presets)
  void setTextFieldValue(String value) {
    textFieldController.text = value;
  }

  /// Gets and clears the text field value (for sending)
  String _takeTextFieldValue() {
    final value = textFieldController.text;
    textFieldController.clear();
    return value;
  }

  // ============================================================
  // Image Attachments
  // ============================================================

  final List<File> _imageFiles = [];

  /// The list of attached image files
  List<File> get imageFiles => List.unmodifiable(_imageFiles);

  /// Whether there are any image attachments
  bool get hasImageAttachments => _imageFiles.isNotEmpty;

  /// Handles image picking and compression
  Future<void> pickImages({
    VoidCallback? onPermissionDenied,
    int quality = 10,
  }) async {
    // Check permissions
    final hasPermission = await _permissionService.requestPhotoPermission(
      onDenied: onPermissionDenied,
    );
    if (!hasPermission) return;

    // Pick images
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );
    // await _picker.pickMultiImage(limit: maxImages);

    if (pickedImage == null) return;

    // Compress and save
    final compressedFile = await _imageService.compressAndSave(
      pickedImage.path,
      quality: quality,
    );

    // Add an empty path if the image could not be compressed to show error
    if (compressedFile != null) {
      _imageFiles.add(compressedFile);
    } else {
      _imageFiles.add(File(''));
    }

    notifyListeners();
  }

  /// Deletes a single image and removes it from the list
  Future<void> removeImage(File imageFile) async {
    await _imageService.deleteImage(imageFile);
    _imageFiles.remove(imageFile);
    notifyListeners();
  }

  /// Gets and clears the current images (for sending)
  List<File> _takeImages() {
    final images = _imageFiles.toList();
    _imageFiles.clear();
    return images;
  }

  // ============================================================
  // Operations
  // ============================================================

  /// Handles sending a message
  /// Returns true if the message was sent successfully
  Future<bool> sendMessage({
    required Future<void> Function() onModelSelectionRequired,
    required void Function() onServerNotConfigured,
  }) async {
    // Early return if nothing to send or currently streaming
    if (!hasText || isStreaming) {
      return false;
    }

    // Check if server is configured
    if (!isServerConfigured) {
      onServerNotConfigured();
      return false;
    }

    // If no current chat, need to create one
    if (_chatProvider.currentChat == null) {
      // If no model selected, request selection
      if (_selectedModel == null) {
        await onModelSelectionRequired();
      }

      // If still no model after selection, abort
      if (_selectedModel == null) {
        return false;
      }

      // Create a new chat with the selected model
      await _chatProvider.createNewChat(_selectedModel!);

      // Take the prompt and images and refresh the presets
      final prompt = _takeTextFieldValue();
      final images = _takeImages();
      _presets = ChatPresets.randomPresets;

      // Notify listeners
      notifyListeners();

      // Send the prompt
      await _chatProvider.sendPrompt(prompt, images: images);

      // Generate title for the new chat
      await _chatProvider.generateTitleForCurrentChat();
    } else {
      // Get and clear the prompt and images
      final prompt = _takeTextFieldValue();
      final images = _takeImages();

      // Notify listeners (text field is cleared)
      notifyListeners();

      // Send the prompt
      await _chatProvider.sendPrompt(prompt, images: images);
    }

    return true;
  }
}
