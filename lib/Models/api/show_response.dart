/// Response from POST /api/show
class ApiShowResponse {
  final String modelfile;
  final String parameters;
  final String template;
  final ApiShowModelDetails details;
  final Map<String, dynamic> modelInfo;
  final List<String> capabilities;

  ApiShowResponse({
    required this.modelfile,
    required this.parameters,
    required this.template,
    required this.details,
    required this.modelInfo,
    required this.capabilities,
  });

  factory ApiShowResponse.fromJson(Map<String, dynamic> json) {
    return ApiShowResponse(
      modelfile: json['modelfile'] ?? '',
      parameters: json['parameters'] ?? '',
      template: json['template'] ?? '',
      details: ApiShowModelDetails.fromJson(json['details'] ?? {}),
      modelInfo: json['model_info'] ?? {},
      capabilities: json['capabilities'] != null ? List<String>.from(json['capabilities']) : [],
    );
  }
}

/// Model details from /api/show response
class ApiShowModelDetails {
  final String parentModel;
  final String format;
  final String family;
  final List<String>? families;
  final String parameterSize;
  final String quantizationLevel;

  ApiShowModelDetails({
    required this.parentModel,
    required this.format,
    required this.family,
    this.families,
    required this.parameterSize,
    required this.quantizationLevel,
  });

  factory ApiShowModelDetails.fromJson(Map<String, dynamic> json) {
    return ApiShowModelDetails(
      parentModel: json['parent_model'] ?? '',
      format: json['format'] ?? '',
      family: json['family'] ?? '',
      families: json['families'] != null ? List<String>.from(json['families']) : null,
      parameterSize: json['parameter_size'] ?? '',
      quantizationLevel: json['quantization_level'] ?? '',
    );
  }
}
