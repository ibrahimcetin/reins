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

  // ? Instead of storing current chat in a separate variable, can we use the selectedChatIndex
  // ? to get the current chat from the chats list?
  OllamaChat? _currentChat;
  OllamaChat? get currentChat => _currentChat;

  List<OllamaChat> _chats = [];
  List<OllamaChat> get chats => _chats;

  int _currentChatIndex = 0;
  int get selectedDestination => _currentChatIndex;

  final Set<int> _activeChatStreams = {};
  bool get isCurrentChatStreaming =>
      _activeChatStreams.contains(_currentChat?.id);

  ChatProvider() {
    _initialize();
  }

  _initialize() async {
    _updateOllamaServiceAddress();

    await _databaseService.open("ollama_chat.db");
    _chats = await _databaseService.getAllChats();
    notifyListeners();
  }

  destinationChatSelected(int destination) {
    _currentChatIndex = destination;

    if (destination == 0) {
      _resetChat();
    } else {
      final chat = _chats[destination - 1];
      _loadChat(chat);
    }

    notifyListeners();
  }

  _resetChat() {
    _currentChat = null;

    _messages.clear();
    _textFieldController.clear();

    notifyListeners();
  }

  _loadChat(OllamaChat chat) async {
    _currentChat = chat;
    _messages = await _databaseService.getMessages(chat.id);

    _textFieldController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    notifyListeners();
  }

  createNewChat(OllamaModel model) async {
    _currentChat = await _databaseService.createChat(model.model);

    _chats.insert(0, _currentChat!);

    _currentChatIndex = 1;
    notifyListeners();
  }

  deleteCurrentChat() async {
    final chat = _currentChat;

    if (chat == null) {
      return;
    }

    _chats.removeWhere((element) => element.id == chat.id);
    _activeChatStreams.remove(chat.id);

    await _databaseService.deleteChat(chat.id);

    destinationChatSelected(0);
  }

  sendUserPrompt() async {
    // Save the chat where the prompt was sent
    final associatedChat = _currentChat!;

    // Get the user prompt and clear the text field
    final prompt = _getUserPrompt();

    // Save the user prompt to the database
    await _databaseService.addMessage(prompt, associatedChat.id);

    // Update the chat list to show the latest chat at the top
    await _moveCurrentChatToTop();

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
          _messages.isNotEmpty &&
          _messages.last.createdAt != ollamaMessage.createdAt) {
        _messages.add(ollamaMessage);
      }

      notifyListeners();
    }

    return ollamaMessage;
  }

  cancelCurrentStreaming() {
    _activeChatStreams.remove(_currentChat?.id);
    notifyListeners();
  }

  _moveCurrentChatToTop() async {
    _chats = await _databaseService.getAllChats();
    _currentChatIndex = 1;
    notifyListeners();
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
