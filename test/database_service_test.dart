import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:ollama_chat/Services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test("Test database open", () async {
    final service = DatabaseService();

    await service.open('test_database.db');
  });

  test("Test database create chat", () async {
    final service = DatabaseService();

    await service.open('test_database.db');

    await service.createChat("llama3.2-vision");
  });

  test("Test database add message", () async {
    final service = DatabaseService();

    await service.open('test_database.db');

    final message = OllamaMessage(
      "Hello, this is a test message.",
      role: OllamaMessageRole.user,
    );

    await service.addMessage(message, 1);
  });
}
