class OllamaModel {
  String name;
  String model;
  DateTime modifiedAt;
  int size;
  String digest;
  OllamaModelDetails details;

  OllamaModel({
    required this.name,
    required this.model,
    required this.modifiedAt,
    required this.size,
    required this.digest,
    required this.details,
  });

  factory OllamaModel.fromJson(Map<String, dynamic> json) => OllamaModel(
        name: json["name"],
        model: json["model"],
        modifiedAt: DateTime.parse(json["modified_at"]),
        size: json["size"],
        digest: json["digest"],
        details: OllamaModelDetails.fromJson(json["details"]),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "model": model,
        "modified_at": modifiedAt.toIso8601String(),
        "size": size,
        "digest": digest,
        "details": details.toJson(),
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

class OllamaModelDetails {
  String parentModel;
  String format;
  String family;
  List<String> families;
  String parameterSize;
  String quantizationLevel;

  OllamaModelDetails({
    required this.parentModel,
    required this.format,
    required this.family,
    required this.families,
    required this.parameterSize,
    required this.quantizationLevel,
  });

  factory OllamaModelDetails.fromJson(Map<String, dynamic> json) =>
      OllamaModelDetails(
        parentModel: json["parent_model"],
        format: json["format"],
        family: json["family"],
        families: List<String>.from(json["families"].map((x) => x)),
        parameterSize: json["parameter_size"],
        quantizationLevel: json["quantization_level"],
      );

  Map<String, dynamic> toJson() => {
        "parent_model": parentModel,
        "format": format,
        "family": family,
        "families": List<dynamic>.from(families.map((x) => x)),
        "parameter_size": parameterSize,
        "quantization_level": quantizationLevel,
      };
}
