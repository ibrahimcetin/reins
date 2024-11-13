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

  final _scrollController = ScrollController();
  ScrollController get scrollController => _scrollController;

  final _ollamaService = OllamaService(
    model: "llama3.2-vision:latest",
    // baseUrl: "https://ollama.loca.lt",
  );
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

    // Jump to the bottom of the chat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
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

  Future<void> sendPrompt() async {
    final prompt = _getPrompt();

    _messages.add(prompt);
    notifyListeners();

    await _databaseService.addMessage(prompt, _chat!.id);

    _scrollToBottom();

    final ollamaMessage = await _ollamaService.chat(_messages);
    _messages.add(ollamaMessage);
    notifyListeners();

    await _databaseService.addMessage(ollamaMessage, _chat!.id);

    _scrollToBottom();
  }

  OllamaMessage _getPrompt() {
    final message = OllamaMessage(
      _textFieldController.text.trim(),
      role: OllamaMessageRole.user,
    );

    _textFieldController.clear();

    return message;
  }

  void _scrollToBottom() {
    // If the scroll position is not at the bottom, do not scroll.
    // This is to prevent the scroll position from changing when the user
    // is reading previous messages.
    // if (_scrollController.hasClients &&
    //     _scrollController.position.pixels !=
    //         _scrollController.position.maxScrollExtent &&
    //     _messages.last.role != OllamaMessageRole.user) {
    //   return;
    // }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
  }
}
