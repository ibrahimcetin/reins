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

  OllamaChat? _currentChat;
  OllamaChat? get currentChat => _currentChat;

  List<OllamaChat> _chats = [];
  List<OllamaChat> get chats => _chats;

  int _selectedChatIndex = 0;
  int get selectedChatIndex => _selectedChatIndex;

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
    _selectedChatIndex = destination;

    if (destination == 0) {
      emptyChat();
    } else {
      final chat = _chats[destination - 1];
      selectChat(chat);
    }

    notifyListeners();
  }

  void emptyChat() {
    _currentChat = null;

    _messages.clear();
    _textFieldController.clear();

    notifyListeners();
  }

  Future selectChat(OllamaChat chat) async {
    _currentChat = chat;
    _messages = await _databaseService.getMessages(chat.id);

    _textFieldController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    notifyListeners();
  }

  Future<void> createChat(OllamaModel model) async {
    _currentChat = await _databaseService.createChat(model.model);

    _chats.insert(0, _currentChat!);

    _selectedChatIndex = 1;
    notifyListeners();
  }

  Future deleteChat() async {
    if (_currentChat == null) {
      return;
    }

    await _databaseService.deleteChat(_currentChat!.id);

    _chats.remove(_currentChat!);
    notifyListeners();

    destinationChatSelected(0);
  }

  Future<void> sendUserPrompt() async {
    // Save the chat where the prompt was sent
    final associatedChat = _currentChat!;

    // Get the user prompt and clear the text field
    final prompt = _getUserPrompt();

    // Save the user prompt to the database
    await _databaseService.addMessage(prompt, associatedChat.id);

    // Update the chat list to show the latest chat at the top
    // ? Should we extract this to a separate method?
    _chats = await _databaseService.getAllChats();
    _selectedChatIndex = 1;
    notifyListeners();

    // Stream the Ollama message
    final ollamaMessage = await _streamOllamaMessage(associatedChat);

    // Save the Ollama message to the database
    await _databaseService.addMessage(ollamaMessage, associatedChat.id);
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

  Future<OllamaMessage> _streamOllamaMessage(OllamaChat associatedChat) async {
    final stream = _ollamaService.chatStream(
      _messages,
      model: associatedChat.model,
    );

    OllamaMessage? ollamaMessage;

    await for (final message in stream) {
      if (ollamaMessage == null) {
        ollamaMessage = message;

        if (associatedChat.id == _currentChat?.id) {
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
      if (associatedChat.id == _currentChat?.id &&
          _messages.last.createdAt != ollamaMessage.createdAt) {
        _messages.add(ollamaMessage);
      }

      notifyListeners();
    }

    return ollamaMessage!;
  }

  Future<List<OllamaModel>> fetchAvailableModels() async {
    return await _ollamaService.listModels();
  }

  _updateOllamaServiceAddress() {
    final settingsBox = Hive.box('settings');
    _ollamaService.baseUrl = settingsBox.get('serverAddress');

    settingsBox.listenable().addListener(() {
      _ollamaService.baseUrl = settingsBox.get('serverAddress');
    });
  }
}
