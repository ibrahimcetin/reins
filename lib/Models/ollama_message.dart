import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:reins/Constants/constants.dart';
import 'package:uuid/uuid.dart';

class OllamaMessage {
  /// The unique identifier of the message.
  String id;

  /// The text content of the message.
  String content;

  /// The image content of the message.
  List<File>? images;

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
            ? OllamaMessageRole.fromString(json["message"]["role"])
            : OllamaMessageRole.assistant, // For generated messages (default)
        images: null, // TODO: Implement image support
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
      images: _constructImages(map['images']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      model: map['model'],
    );
  }

  Future<Map<String, dynamic>> toJson() async => {
        "model": model,
        "created_at": createdAt.toIso8601String(),
        "message": {
          "role": role.toCaseString(),
          "content": content,
          "images": await _base64EncodeImages(),
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

  Future<Map<String, dynamic>> toChatJson() async => {
        "role": role.toCaseString(),
        "content": content,
        "images": await _base64EncodeImages(),
      };

  Map<String, dynamic> toDatabaseMap() => {
        'message_id': id,
        'content': content,
        'images': _breakImages(images),
        'role': role.toCaseString(),
        'timestamp': createdAt.millisecondsSinceEpoch,
      };

  void updateMetadataFrom(OllamaMessage message) {
    done = message.done;
    doneReason = message.doneReason;
    context = message.context;
    totalDuration = message.totalDuration;
    loadDuration = message.loadDuration;
    promptEvalCount = message.promptEvalCount;
    promptEvalDuration = message.promptEvalDuration;
    evalCount = message.evalCount;
    evalDuration = message.evalDuration;
  }

  Future<List<String>?> _base64EncodeImages() async {
    if (images != null) {
      return await Future.wait(images!.map(
        (file) async => base64Encode(await file.readAsBytes()),
      ));
    }

    return null;
  }

  static List<File>? _constructImages(String? raw) {
    if (raw != null) {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((imageRelativePath) {
        return File(path.join(
          PathManager.instance.documentsDirectory.path,
          imageRelativePath,
        ));
      }).toList();
    }

    return null;
  }

  String? _breakImages(List<File>? images) {
    if (images != null) {
      final relativePathImages = images.map((file) {
        return path.relative(
          file.path,
          from: PathManager.instance.documentsDirectory.path,
        );
      }).toList();

      return jsonEncode(relativePathImages);
    }

    return null;
  }
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

  String toCaseString() {
    return toString().split('.').last;
  }
}
