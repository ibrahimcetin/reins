import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  late Database db;

  Future open(String path) async {
    db = await openDatabase(
      join(await getDatabasesPath(), path),
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''CREATE TABLE chats (
chat_id INTEGER PRIMARY KEY AUTOINCREMENT,
model TEXT NOT NULL,
chat_title TEXT NOT NULL,
options TEXT
);
''');

        await db.execute('''CREATE TABLE messages (
message_id INTEGER PRIMARY KEY AUTOINCREMENT,
chat_id INTEGER NOT NULL,
content TEXT NOT NULL,
role TEXT CHECK(role IN ('user', 'assistant', 'system')) NOT NULL,
timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (chat_id) REFERENCES chats(chat_id) ON DELETE CASCADE
);''');
      },
    );
  }

  Future createChat(String model) async {
    await db.insert('chats', {
      'model': model,
      'chat_title': 'New Chat',
      'options': null,
    });
  }

  Future addMessage(OllamaMessage message, int chatId) async {
    await db.insert('messages', {
      'chat_id': chatId,
      'content': message.content,
      'role': message.role.toString().split('.').last,
      'timestamp': message.createdAt.millisecondsSinceEpoch,
    });
  }
}
