import 'package:reins/Models/api/tags_response.dart';
import 'package:reins/Models/api/show_response.dart';
import 'package:reins/Models/model_capabilities.dart';

/// Domain model representing an Ollama model.
/// Combines data from /api/tags and optionally /api/show.
class OllamaModel {
  final String name;
  final String model;
  final DateTime modifiedAt;
  final int size;
  final String digest;
  final String parameterSize;
  final ModelCapabilities? capabilities;

  OllamaModel({
    required this.name,
    required this.model,
    required this.modifiedAt,
    required this.size,
    required this.digest,
    required this.parameterSize,
    this.capabilities,
  });

  /// Creates an OllamaModel from /api/tags and optional /api/show response
  factory OllamaModel.from(ApiTagsModel tagsModel, ApiShowResponse? showResponse) {
    return OllamaModel(
      name: tagsModel.name,
      model: tagsModel.model,
      modifiedAt: tagsModel.modifiedAt,
      size: tagsModel.size,
      digest: tagsModel.digest,
      parameterSize: tagsModel.details.parameterSize,
      capabilities: showResponse != null ? ModelCapabilities.fromList(showResponse.capabilities) : null,
    );
  }

  /// For backward compatibility with existing JSON serialization
  factory OllamaModel.fromJson(Map<String, dynamic> json) => OllamaModel(
        name: json["name"],
        model: json["model"],
        modifiedAt: DateTime.parse(json["modified_at"]),
        size: json["size"],
        digest: json["digest"],
        parameterSize: json["details"]["parameter_size"] ?? '',
        capabilities: null,
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "model": model,
        "modified_at": modifiedAt.toIso8601String(),
        "size": size,
        "digest": digest,
        "parameter_size": parameterSize,
      };

  @override
  String toString() {
    return name;
  }

  @override
  int get hashCode => digest.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OllamaModel && other.digest == digest;
  }
}
