import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:ollama_chat/Services/database_service.dart';
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

  test("Test database open", () async {
    await service.open('test_database.db');
  });

  test("Test database create chat", () async {
    final chat = await service.createChat("llama3.2-vision");

    expect(chat.id, isPositive);
    expect(chat.model, equals("llama3.2-vision"));
    expect(chat.title, "New Chat");
    expect(chat.options, isNull);
  });

  test("Test database get chat", () async {
    final chat = await service.createChat("llama3.2-vision");

    final retrievedChat = await service.getChat(chat.id);
    expect(retrievedChat.id, chat.id);
    expect(retrievedChat.model, chat.model);
    expect(retrievedChat.title, chat.title);
    expect(retrievedChat.options, chat.options);
  });

  test("Test database update chat", () async {
    final chat = await service.createChat("llama3.2-vision");

    await service.updateChat(chat, newModel: "llama3.2");

    final updatedChat = await service.getChat(chat.id);
    expect(updatedChat.model, "llama3.2");
    expect(updatedChat.title, "New Chat");
    expect(updatedChat.options, isNull);
  });

  test("Test database add message", () async {
    final message = OllamaMessage(
      "Hello, this is a test message.",
      role: OllamaMessageRole.user,
    );

    await service.addMessage(message, 1);

    final messages = await service.getMessages(1);
    expect(messages.first.content, "Hello, this is a test message.");
    expect(messages.first.role, OllamaMessageRole.user);
  });

  test("Test database get all chats", () async {
    final chats = await service.getAllChats();

    if (chats.isNotEmpty) {
      expect(chats.first.id, isPositive);
      expect(chats.first.model, equals("llama3.2-vision"));
      expect(chats.first.title, "New Chat");
      expect(chats.first.options, isNull);
    }
  });
}
