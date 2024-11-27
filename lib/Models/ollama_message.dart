import 'package:uuid/uuid.dart';

class OllamaMessage {
  /// The unique identifier of the message.
  String id;

  /// The text content of the message.
  String content;

  /// The image content of the message.
  List<dynamic>? images; // TODO: Implement image support

  /// The date and time the message was created.
  DateTime createdAt;

  /// The role of the message.
  OllamaMessageRole role;

  /// The model used to generate the message.
  String? model;

  // Metadata fields
  bool? done;
  String? doneReason;
  List<int>? context;
  int? totalDuration;
  int? loadDuration;
  int? promptEvalCount;
  int? promptEvalDuration;
  int? evalCount;
  int? evalDuration;

  OllamaMessage(
    this.content, {
    String? id,
    required this.role,
    this.images,
    DateTime? createdAt,
    this.model,
    this.done,
    this.doneReason,
    this.context,
    this.totalDuration,
    this.loadDuration,
    this.promptEvalCount,
    this.promptEvalDuration,
    this.evalCount,
    this.evalDuration,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory OllamaMessage.fromJson(Map<String, dynamic> json) => OllamaMessage(
        json["message"] != null
            ? json["message"]["content"] // For chat messages
            : json["response"], // For generated messages
        role: json["message"] != null
            ? OllamaMessageRole.fromString(
                json["message"]["role"]) // For chat messages
            : OllamaMessageRole.assistant, // For generated messages (default)
        images: json["message"]?["images"] != null
            ? List<dynamic>.from(json["message"]["images"])
            : null,
        createdAt: DateTime.parse(json["created_at"]),
        model: json["model"],
        // Metadata fields
        done: json["done"],
        doneReason: json["done_reason"],
        context: json["context"] != null
            ? List<int>.from(json["context"].map((x) => x))
            : null,
        totalDuration: json["total_duration"],
        loadDuration: json["load_duration"],
        promptEvalCount: json["prompt_eval_count"],
        promptEvalDuration: json["prompt_eval_duration"],
        evalCount: json["eval_count"],
        evalDuration: json["eval_duration"],
      );

  factory OllamaMessage.fromDatabase(Map<String, dynamic> map) {
    return OllamaMessage(
      map['content'],
      id: map['message_id'],
      role: OllamaMessageRole.fromString(map['role']),
      images: map['images'] != null ? List<dynamic>.from(map['images']) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      model: map['model'],
    );
  }

  Map<String, dynamic> toJson() => {
        "model": model,
        "created_at": createdAt.toIso8601String(),
        "message": {
          "role": role.toString(),
          "content": content,
          "images": images,
        },
        "done": done,
        "done_reason": doneReason,
        "context":
            context == null ? null : List<dynamic>.from(context!.map((x) => x)),
        "total_duration": totalDuration,
        "load_duration": loadDuration,
        "prompt_eval_count": promptEvalCount,
        "prompt_eval_duration": promptEvalDuration,
        "eval_count": evalCount,
        "eval_duration": evalDuration,
      };

  Map<String, dynamic> toChatJson() => {
        "role": role.toString().split('.').last,
        "content": content,
        "images": images,
      };
}

enum OllamaMessageRole {
  user,
  assistant,
  system;

  factory OllamaMessageRole.fromString(String role) {
    switch (role) {
      case 'user':
        return OllamaMessageRole.user;
      case 'assistant':
        return OllamaMessageRole.assistant;
      case 'system':
        return OllamaMessageRole.system;
      default:
        throw ArgumentError('Unknown role: $role');
    }
  }
}
