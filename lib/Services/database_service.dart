import 'package:ollama_chat/Models/ollama_chat.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  late Database db;

  Future<void> open(String path) async {
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

  Future<OllamaChat> createChat(String model) async {
    await db.insert('chats', {
      'model': model,
      'chat_title': 'New Chat',
      'options': null,
    });

    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      orderBy: 'chat_id DESC',
      limit: 1,
    );

    return OllamaChat.fromMap(maps.first);
  }

  Future<void> addMessage(OllamaMessage message, int chatId) async {
    // TODO: Get parameters from instance method like toDatabaseParams
    await db.insert('messages', {
      'chat_id': chatId,
      'content': message.content,
      'role': message.role.toString().split('.').last,
      'timestamp': message.createdAt.millisecondsSinceEpoch,
    });
  }

  Future<List<OllamaChat>> getAllChats() async {
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''SELECT chats.chat_id, chats.chat_title, chats.model, chats.options, MAX(messages.timestamp) AS last_update
FROM chats
LEFT JOIN messages ON chats.chat_id = messages.chat_id
GROUP BY chats.chat_id
ORDER BY last_update DESC;''');

    return List.generate(maps.length, (i) {
      return OllamaChat.fromMap(maps[i]);
    });
  }

  Future<List<OllamaMessage>> getMessages(int chatId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return OllamaMessage.fromDatabase(maps[i]);
    });
  }

  Future<void> deleteChat(int chatId) async {
    await db.delete(
      'chats',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );

    await db.delete(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> close() async => db.close();
}
