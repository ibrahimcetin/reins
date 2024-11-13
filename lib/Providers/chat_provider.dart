import 'package:ollama_chat/Models/ollama_chat.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:ollama_chat/Services/database_service.dart';
import 'package:ollama_chat/Services/ollama_service.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  List<OllamaMessage> _messages = [];
  List<OllamaMessage> get messages => _messages;

  final _textFieldController = TextEditingController();
  TextEditingController get textFieldController => _textFieldController;

  final _ollamaService = OllamaService();
  final _databaseService = DatabaseService();

  OllamaChat? _chat;
  OllamaChat? get chat => _chat;

  List<OllamaChat> _chats = [];
  List<OllamaChat> get chats => _chats;

  int _selectedChatIndex = 0;
  int get selectedChatIndex => _selectedChatIndex;

  ChatProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _databaseService.open("ollama_chat.db");

    _chats = await _databaseService.getAllChats();
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
    _chat = null;

    _messages.clear();
    _textFieldController.clear();

    notifyListeners();
  }

  Future selectChat(OllamaChat chat) async {
    _chat = chat;

    _messages = await _databaseService.getMessages(chat.id);
    _textFieldController.clear();

    notifyListeners();
  }

  Future<void> createChat(String model) async {
    _chat = await _databaseService.createChat(model);

    _chats.insert(0, _chat!);

    _selectedChatIndex = 1;
    notifyListeners();
  }

  Future deleteChat() async {
    if (_chat == null) {
      return;
    }

    await _databaseService.deleteChat(_chat!.id);

    _chats.remove(_chat!);
    notifyListeners();

    destinationChatSelected(0);
  }

  Future<void> sendUserPrompt() async {
    final prompt = _getUserPrompt();

    await _databaseService.addMessage(prompt, _chat!.id);

    final ollamaMessage = await _streamOllamaMessages();

    await _databaseService.addMessage(ollamaMessage, _chat!.id);
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

  Future<OllamaMessage> _streamOllamaMessages() async {
    final stream = _ollamaService.chatStream(_messages, model: _chat!.model);

    OllamaMessage? ollamaMessage;

    await for (final message in stream) {
      if (ollamaMessage == null) {
        _messages.add(message);
        ollamaMessage = message;
      } else {
        ollamaMessage.content += message.content;
      }

      notifyListeners();
    }

    return ollamaMessage!;
  }
}
