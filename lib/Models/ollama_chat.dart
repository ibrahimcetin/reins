class OllamaChat {
  final String id;
  final String model;
  final String title;
  final String? systemPrompt;
  final Map<String, dynamic>? options;

  OllamaChat({
    required this.id,
    required this.model,
    required this.title,
    this.systemPrompt,
    this.options,
  });

  factory OllamaChat.fromMap(Map<String, dynamic> map) {
    return OllamaChat(
      id: map['chat_id'],
      model: map['model'],
      title: map['chat_title'],
      systemPrompt: map['system_prompt'],
      options: map['options'],
    );
  }
}
