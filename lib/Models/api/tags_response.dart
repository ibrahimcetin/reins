/// Response from GET /api/tags
class ApiTagsResponse {
  final List<ApiTagsModel> models;

  ApiTagsResponse({required this.models});

  factory ApiTagsResponse.fromJson(Map<String, dynamic> json) {
    return ApiTagsResponse(
      models: (json['models'] as List).map((m) => ApiTagsModel.fromJson(m)).toList(),
    );
  }
}

/// Individual model from /api/tags response
class ApiTagsModel {
  final String name;
  final String model;
  final DateTime modifiedAt;
  final int size;
  final String digest;
  final ApiTagsModelDetails details;

  ApiTagsModel({
    required this.name,
    required this.model,
    required this.modifiedAt,
    required this.size,
    required this.digest,
    required this.details,
  });

  factory ApiTagsModel.fromJson(Map<String, dynamic> json) {
    return ApiTagsModel(
      name: json['name'],
      model: json['model'],
      modifiedAt: DateTime.parse(json['modified_at']),
      size: json['size'],
      digest: json['digest'],
      details: ApiTagsModelDetails.fromJson(json['details']),
    );
  }
}

/// Model details from /api/tags response
class ApiTagsModelDetails {
  final String parentModel;
  final String format;
  final String family;
  final List<String>? families;
  final String parameterSize;
  final String quantizationLevel;

  ApiTagsModelDetails({
    required this.parentModel,
    required this.format,
    required this.family,
    this.families,
    required this.parameterSize,
    required this.quantizationLevel,
  });

  factory ApiTagsModelDetails.fromJson(Map<String, dynamic> json) {
    return ApiTagsModelDetails(
      parentModel: json['parent_model'] ?? '',
      format: json['format'] ?? '',
      family: json['family'] ?? '',
      families: json['families'] != null ? List<String>.from(json['families']) : null,
      parameterSize: json['parameter_size'] ?? '',
      quantizationLevel: json['quantization_level'] ?? '',
    );
  }
}
