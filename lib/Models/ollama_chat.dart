class OllamaChat {
  final int id;
  final String model;
  final String title;
  final Map<String, dynamic>? options;

  OllamaChat({
    required this.id,
    required this.model,
    required this.title,
    this.options,
  });

  factory OllamaChat.fromMap(Map<String, dynamic> map) {
    return OllamaChat(
      id: map['chat_id'],
      model: map['model'],
      title: map['chat_title'],
      options: map['options'],
    );
  }
}
