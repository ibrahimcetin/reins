import 'package:ollama_chat/Models/ollama_chat.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:ollama_chat/Models/ollama_model.dart';
import 'package:ollama_chat/Services/database_service.dart';
import 'package:ollama_chat/Services/ollama_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatProvider extends ChangeNotifier {
  List<OllamaMessage> _messages = [];
  List<OllamaMessage> get messages => _messages;

  final _textFieldController = TextEditingController();
  TextEditingController get textFieldController => _textFieldController;

  final _ollamaService = OllamaService();
  final _databaseService = DatabaseService();

  List<OllamaChat> _chats = [];
  List<OllamaChat> get chats => _chats;

  int _currentChatIndex = -1;
  int get selectedDestination => _currentChatIndex + 1;

  OllamaChat? get currentChat =>
      _currentChatIndex == -1 ? null : _chats[_currentChatIndex];

  final Set<int> _activeChatStreams = {};
  bool get isCurrentChatStreaming =>
      _activeChatStreams.contains(currentChat?.id);

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
    _textFieldController.clear();

    notifyListeners();
  }

  Future<void> _loadCurrentChat() async {
    _messages = await _databaseService.getMessages(currentChat!.id);

    _textFieldController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    notifyListeners();
  }

  Future<void> createNewChat(OllamaModel model) async {
    final chat = await _databaseService.createChat(model.model);

    _chats.insert(0, chat);
    _currentChatIndex = 0;

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

  Future<void> sendUserPrompt() async {
    // Save the chat where the prompt was sent
    final associatedChat = currentChat!;

    // Get the user prompt and clear the text field
    final prompt = _getUserPrompt();

    // Save the user prompt to the database
    await _databaseService.addMessage(prompt, associatedChat.id);

    // Update the chat list to show the latest chat at the top
    _moveCurrentChatToTop();

    // Stream the Ollama message
    OllamaMessage? ollamaMessage;

    try {
      _activeChatStreams.add(associatedChat.id);
      ollamaMessage = await _streamOllamaMessage(associatedChat);
    } catch (_) {
      // TODO: Handle the error, show an error occured
    } finally {
      _activeChatStreams.remove(associatedChat.id);
      notifyListeners();
    }

    // Save the Ollama message to the database
    if (ollamaMessage != null) {
      await _databaseService.addMessage(ollamaMessage, associatedChat.id);
    }
  }

  OllamaMessage _getUserPrompt() {
    final message = OllamaMessage(
      _textFieldController.text.trim(),
      role: OllamaMessageRole.user,
    );

    _textFieldController.clear();

    _messages.add(message);
    notifyListeners();

    return message;
  }

  Future<OllamaMessage?> _streamOllamaMessage(OllamaChat associatedChat) async {
    final stream = _ollamaService.chatStream(
      _messages,
      model: associatedChat.model,
    );

    OllamaMessage? ollamaMessage;

    await for (final message in stream) {
      // If the chat id is not in the active chat streams, it means the stream
      // is cancelled by the user. So, we need to break the loop.
      if (_activeChatStreams.contains(associatedChat.id) == false) {
        break;
      }

      if (ollamaMessage == null) {
        ollamaMessage = message;

        if (associatedChat.id == currentChat?.id) {
          _messages.add(ollamaMessage);
        }
      } else {
        ollamaMessage.content += message.content;
      }

      // If the chat changed previously by user, and come back to the same chat later,
      // the latest message will be user's message. So, we need to readd the ollamaMessage
      // to be able to show stream in the chat.
      //
      // createdAt property is used like a unique identifier for messages.
      if (associatedChat.id == currentChat?.id &&
          _messages.isNotEmpty &&
          _messages.last.createdAt != ollamaMessage.createdAt) {
        _messages.add(ollamaMessage);
      }

      notifyListeners();
    }

    return ollamaMessage;
  }

  void cancelCurrentStreaming() {
    _activeChatStreams.remove(currentChat?.id);
    notifyListeners();
  }

  void _moveCurrentChatToTop() {
    final chat = _chats.removeAt(_currentChatIndex);
    _chats.insert(0, chat);
    _currentChatIndex = 0;

    notifyListeners();
  }

  Future<List<OllamaModel>> fetchAvailableModels() async {
    return await _ollamaService.listModels();
  }

  void _updateOllamaServiceAddress() {
    final settingsBox = Hive.box('settings');
    _ollamaService.baseUrl = settingsBox.get('serverAddress');

    settingsBox.listenable().addListener(() {
      _ollamaService.baseUrl = settingsBox.get('serverAddress');
    });
  }
}
