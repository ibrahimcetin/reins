import 'dart:io';

import 'package:ollama_chat/Models/ollama_chat.dart';
import 'package:ollama_chat/Models/ollama_exception.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:ollama_chat/Models/ollama_model.dart';
import 'package:ollama_chat/Services/database_service.dart';
import 'package:ollama_chat/Services/ollama_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatProvider extends ChangeNotifier {
  List<OllamaMessage> _messages = [];
  List<OllamaMessage> get messages => _messages;

  final _ollamaService = OllamaService();
  final _databaseService = DatabaseService();

  List<OllamaChat> _chats = [];
  List<OllamaChat> get chats => _chats;

  int _currentChatIndex = -1;
  int get selectedDestination => _currentChatIndex + 1;

  OllamaChat? get currentChat =>
      _currentChatIndex == -1 ? null : _chats[_currentChatIndex];

  final Map<String, OllamaMessage?> _activeChatStreams = {};

  bool get isCurrentChatStreaming =>
      _activeChatStreams.containsKey(currentChat?.id);

  bool get isCurrentChatThinking =>
      currentChat != null &&
      _activeChatStreams.containsKey(currentChat?.id) &&
      _activeChatStreams[currentChat?.id] == null;

  /// A map of chat errors, indexed by chat ID.
  final Map<String, OllamaException> _chatErrors = {};

  /// The current chat error. This is the error associated with the current chat.
  /// If there is no error, this will be `null`.
  ///
  /// This is used to display error messages in the chat view.
  OllamaException? get currentChatError => _chatErrors[currentChat?.id];

  ChatProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _updateOllamaServiceAddress();

    await _databaseService.open("ollama_chat.db");
    _chats = await _databaseService.getAllChats();
    notifyListeners();
  }

  void destinationChatSelected(int destination) {
    _currentChatIndex = destination - 1;

    if (destination == 0) {
      _resetChat();
    } else {
      _loadCurrentChat();
    }

    notifyListeners();
  }

  void _resetChat() {
    _currentChatIndex = -1;

    _messages.clear();

    notifyListeners();
  }

  Future<void> _loadCurrentChat() async {
    _messages = await _databaseService.getMessages(currentChat!.id);

    // Add the streaming message to the chat if it exists
    final streamingMessage = _activeChatStreams[currentChat!.id];
    if (streamingMessage != null) {
      _messages.add(streamingMessage);
    }

    // Unfocus the text field to dismiss the keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    notifyListeners();
  }

  Future<void> createNewChat(OllamaModel model) async {
    final chat = await _databaseService.createChat(model.name);

    _chats.insert(0, chat);
    _currentChatIndex = 0;

    notifyListeners();
  }

  Future<void> updateCurrentChat({
    String? newModel,
    String? newTitle,
    String? newOptions,
  }) async {
    final chat = currentChat;
    if (chat == null) return;

    await _databaseService.updateChat(
      chat,
      newModel: newModel,
      newTitle: newTitle,
      newOptions: newOptions,
    );

    _chats[_currentChatIndex] = (await _databaseService.getChat(chat.id))!;
    notifyListeners();
  }

  Future<void> deleteCurrentChat() async {
    final chat = currentChat;
    if (chat == null) {
      return;
    }

    _chats.remove(chat);
    _activeChatStreams.remove(chat.id);

    await _databaseService.deleteChat(chat.id);

    _resetChat();
  }

  Future<void> sendPrompt(String text) async {
    // Save the chat where the prompt was sent
    final associatedChat = currentChat!;

    // Create a user prompt message and add it to the chat
    final prompt = OllamaMessage(text.trim(), role: OllamaMessageRole.user);
    _messages.add(prompt);

    notifyListeners();

    // Save the user prompt to the database
    await _databaseService.addMessage(prompt, chat: associatedChat);

    await _initializeChatStream(associatedChat);
  }

  Future<void> _initializeChatStream(OllamaChat associatedChat) async {
    // Clear the error message associated with the chat
    if (_chatErrors.remove(associatedChat.id) != null) {
      notifyListeners();
      // Wait for a short time to show the user that the error message is cleared
      await Future.delayed(Duration(milliseconds: 250));
    }

    // Update the chat list to show the latest chat at the top
    _moveCurrentChatToTop();

    // Stream the Ollama message
    _activeChatStreams[associatedChat.id] = null;

    // Notify the listeners to show the thinking indicator
    notifyListeners();

    try {
      await _streamOllamaMessage(associatedChat);
    } on OllamaException catch (error) {
      _chatErrors[associatedChat.id] = error;
    } on SocketException catch (_) {
      _chatErrors[associatedChat.id] =
          OllamaException("Network connection lost.");
    } catch (error) {
      _chatErrors[associatedChat.id] = OllamaException("Something went wrong.");
    }

    // We get the Ollama message from the active chat streams to save it to the database.
    // Because _streamOllamaMessage only returns if it is successed.
    // _activeChatStreams holds the latest message.
    final ollamaMessage = _activeChatStreams[associatedChat.id];

    _activeChatStreams.remove(associatedChat.id);
    notifyListeners();

    // Save the Ollama message to the database
    if (ollamaMessage != null) {
      await _databaseService.addMessage(ollamaMessage, chat: associatedChat);
    }
  }

  Future<OllamaMessage?> _streamOllamaMessage(OllamaChat associatedChat) async {
    final stream = _ollamaService.chatStream(
      _messages,
      model: associatedChat.model,
    );

    OllamaMessage? streamingMessage;
    OllamaMessage? receivedMessage;

    await for (receivedMessage in stream) {
      // If the chat id is not in the active chat streams, it means the stream
      // is cancelled by the user. So, we need to break the loop.
      if (_activeChatStreams.containsKey(associatedChat.id) == false) {
        break;
      }

      if (streamingMessage == null) {
        // Keep the first received message to add the content of the following messages
        streamingMessage = receivedMessage;

        // Update the active chat streams key with the ollama message
        // to be able to show the stream in the chat.
        // We also use this when the user switches between chats while streaming.
        _activeChatStreams[associatedChat.id] = streamingMessage;

        // Be sure the user is in the same chat while the initial message is received
        if (associatedChat.id == currentChat?.id) {
          _messages.add(streamingMessage);
        }
      } else {
        streamingMessage.content += receivedMessage.content;
      }

      notifyListeners();
    }

    if (receivedMessage != null) {
      // Update the metadata of the streaming message with the last received message
      streamingMessage?.updateMetadataFrom(receivedMessage);
    }

    return streamingMessage;
  }

  Future<void> regenerateMessage(OllamaMessage message) async {
    final associatedChat = currentChat!;

    final messageIndex = _messages.indexOf(message);
    if (messageIndex == -1) return;

    final includeMessage = (message.role == OllamaMessageRole.user ? 1 : 0);

    final stayedMessages = _messages.sublist(0, messageIndex + includeMessage);
    final removeMessages = _messages.sublist(messageIndex + includeMessage);

    _messages = stayedMessages;
    notifyListeners();

    await _databaseService.deleteMessages(removeMessages);

    // Reinitialize the chat stream
    await _initializeChatStream(associatedChat);
  }

  Future<void> retryLastPrompt() async {
    if (_messages.isEmpty) return;

    final associatedChat = currentChat!;

    if (_messages.last.role == OllamaMessageRole.assistant) {
      final message = _messages.removeLast();
      await _databaseService.deleteMessage(message.id);
    }

    await _initializeChatStream(associatedChat);

    notifyListeners();
  }

  Future<void> updateMessage(
    OllamaMessage message, {
    String? newContent,
  }) async {
    message.content = newContent ?? message.content;
    notifyListeners();

    await _databaseService.updateMessage(message, newContent: newContent);
  }

  Future<void> deleteMessage(OllamaMessage message) async {
    await _databaseService.deleteMessage(message.id);

    // If the message is in the chat, remove it from the chat
    if (_messages.remove(message)) {
      notifyListeners();
    }
  }

  void cancelCurrentStreaming() {
    _activeChatStreams.remove(currentChat?.id);
    notifyListeners();
  }

  void _moveCurrentChatToTop() {
    if (_currentChatIndex == 0) return;

    final chat = _chats.removeAt(_currentChatIndex);
    _chats.insert(0, chat);
    _currentChatIndex = 0;
  }

  Future<List<OllamaModel>> fetchAvailableModels() async {
    return await _ollamaService.listModels();
  }

  void _updateOllamaServiceAddress() {
    final settingsBox = Hive.box('settings');
    _ollamaService.baseUrl = settingsBox.get('serverAddress');

    settingsBox.listenable(keys: ["serverAddress"]).addListener(() {
      _ollamaService.baseUrl = settingsBox.get('serverAddress');

      // This will update empty chat state to dismiss "Tap to configure server address" message
      notifyListeners();
    });
  }
}
