import 'package:reins/Models/ollama_chat.dart';
import 'package:reins/Models/ollama_message.dart';
import 'package:reins/Services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final databasePath = path.join(await getDatabasesPath(), 'test_database.db');
  await databaseFactoryFfi.deleteDatabase(databasePath);

  final service = DatabaseService();
  await service.open('test_database.db');

  const model = "llama3.2";

  test("Test database open", () async {
    await service.open('test_database.db');
  });

  test("Test database create chat", () async {
    final chat = await service.createChat(model);

    expect(chat.id, isNotEmpty);
    expect(chat.model, model);
    expect(chat.title, "New Chat");
    expect(chat.systemPrompt, isNull);
    expect(chat.options.toJson(), OllamaChatOptions().toJson());
  });

  test("Test database get chat", () async {
    final chat = await service.createChat(model);

    final retrievedChat = (await service.getChat(chat.id))!;
    expect(retrievedChat.id, chat.id);
    expect(retrievedChat.model, chat.model);
    expect(retrievedChat.title, chat.title);
    expect(retrievedChat.systemPrompt, chat.systemPrompt);
    expect(retrievedChat.options.toJson(), chat.options.toJson());
  });

  test("Test database update chat title", () async {
    final chat = await service.createChat(model);

    await service.updateChat(chat, newModel: "llama3.2");

    final updatedChat = (await service.getChat(chat.id))!;
    expect(updatedChat.model, "llama3.2");
    expect(updatedChat.title, "New Chat");
    expect(updatedChat.systemPrompt, isNull);
    expect(chat.options.toJson(), OllamaChatOptions().toJson());
  });

  test('Test database update chat system prompt', () async {
    const systemPrompt =
        "You are Mario from super mario bros, acting as an assistant.";

    final chat = await service.createChat(model);

    await service.updateChat(
      chat,
      newSystemPrompt: systemPrompt,
    );

    final updatedChat = (await service.getChat(chat.id))!;
    expect(updatedChat.model, model);
    expect(updatedChat.title, "New Chat");
    expect(updatedChat.systemPrompt, systemPrompt);
    expect(chat.options.toJson(), OllamaChatOptions().toJson());

    await service.updateChat(updatedChat, newSystemPrompt: null);
  });

  test('Test database update chat options', () async {
    final chat = await service.createChat(model);

    await service.updateChat(
      chat,
      newOptions: OllamaChatOptions(
        mirostat: 1,
        mirostatEta: 0.1,
        mirostatTau: 0.1,
        contextSize: 1,
        repeatLastN: 1,
        repeatPenalty: 0.1,
        temperature: 0.1,
        seed: 1,
      ),
    );

    final updatedChat = (await service.getChat(chat.id))!;
    expect(updatedChat.model, model);
    expect(updatedChat.title, "New Chat");
    expect(updatedChat.systemPrompt, isNull);
    expect(updatedChat.options.mirostat, 1);
    expect(updatedChat.options.mirostatEta, 0.1);
    expect(updatedChat.options.mirostatTau, 0.1);
    expect(updatedChat.options.contextSize, 1);
    expect(updatedChat.options.repeatLastN, 1);
    expect(updatedChat.options.repeatPenalty, 0.1);
    expect(updatedChat.options.temperature, 0.1);
    expect(updatedChat.options.seed, 1);
  });

  test("Test database delete chat", () async {
    final chat = await service.createChat(model);

    await service.deleteChat(chat.id);

    expect(await service.getChat(chat.id), isNull);
  });

  test("Test database get all chats", () async {
    await service.createChat(model);
    final chats = await service.getAllChats();

    if (chats.isNotEmpty) {
      expect(chats.first.id, isNotEmpty);
      expect(chats.first.model, model);
      expect(chats.first.title, "New Chat");
      expect(chats.first.systemPrompt, isNull);
      expect(chats.first.options.toJson(), OllamaChatOptions().toJson());
    }
  });

  test("Test database add message", () async {
    final chat = await service.createChat(model);
    final message = OllamaMessage(
      "Hello, this is a test message.",
      role: OllamaMessageRole.user,
    );

    await service.addMessage(message, chat: chat);

    final messages = await service.getMessages(chat.id);
    expect(messages.length, 1);
    expect(messages.first.id, message.id);
    expect(messages.first.content, message.content);
    expect(messages.first.role, message.role);
  });

  test("Test database get message", () async {
    final chat = await service.createChat(model);
    final message = OllamaMessage(
      "Hello, this is a test message.",
      role: OllamaMessageRole.user,
    );

    await service.addMessage(message, chat: chat);

    final retrievedMessage = await service.getMessage(message.id);
    expect(retrievedMessage, isNotNull);
    expect(retrievedMessage!.id, message.id);
    expect(retrievedMessage.content, message.content);
    expect(retrievedMessage.role, message.role);
  });

  test('Test database update message', () async {
    final chat = await service.createChat(model);

    final message = OllamaMessage("Message", role: OllamaMessageRole.user);
    await service.addMessage(message, chat: chat);

    await service.updateMessage(message, newContent: "Updated message");
    final retrievedMessage = (await service.getMessage(message.id))!;

    expect(retrievedMessage, isNotNull);
    expect(retrievedMessage.id, message.id);
    expect(retrievedMessage.content, 'Updated message');
    expect(retrievedMessage.role, message.role);
  });

  test('Test database delete message', () async {
    final chat = await service.createChat(model);
    final message = OllamaMessage(
      "Hello, this is a test message.",
      role: OllamaMessageRole.user,
    );

    await service.addMessage(message, chat: chat);
    expect(await service.getMessage(message.id), isNotNull);

    await service.deleteMessage(message.id);
    expect(await service.getMessage(message.id), isNull);
  });

  test("Test database get messages", () async {
    final chat = await service.createChat(model);
    final message = OllamaMessage(
      "Hello, this is a test message.",
      role: OllamaMessageRole.user,
    );

    await service.addMessage(message, chat: chat);

    final messages = await service.getMessages(chat.id);
    expect(messages.length, 1);
    expect(messages.first.id, message.id);
    expect(messages.first.content, message.content);
    expect(messages.first.role, message.role);
  });

  test("Test database delete messages", () async {
    final chat = await service.createChat(model);
    final message = OllamaMessage(
      "Hello, this is a test message.",
      role: OllamaMessageRole.user,
    );

    await service.addMessage(message, chat: chat);
    expect(await service.getMessage(message.id), isNotNull);

    await service.deleteMessages([message]);
    expect(await service.getMessage(message.id), isNull);
  });
}
