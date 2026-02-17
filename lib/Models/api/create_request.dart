import 'package:reins/Models/ollama_chat.dart';
import 'package:reins/Models/ollama_message.dart';

/// Request body for POST /api/create
///
/// Creates a model from another model with optional system prompt,
/// parameters, and message history.
class ApiCreateRequest {
  /// Name of the model to create.
  final String model;

  /// Name of an existing model to create the new model from.
  final String from;

  /// A system prompt for the model.
  final String? system;

  /// A dictionary of parameters for the model.
  final Map<String, dynamic>? parameters;

  /// A list of message objects used to seed the conversation.
  final List<OllamaMessage>? messages;

  /// If `false` the response will be returned as a single response object,
  /// rather than a stream of objects.
  final bool stream;

  ApiCreateRequest({
    required this.model,
    required this.from,
    this.system,
    this.parameters,
    this.messages,
    this.stream = false,
  });

  /// Constructs an [ApiCreateRequest] from an [OllamaChat] and optional messages.
  ///
  /// Only non-default parameters are included in the request to avoid
  /// overriding the base model's defaults unnecessarily.
  factory ApiCreateRequest.fromChat(
    String model, {
    required OllamaChat chat,
    List<OllamaMessage>? messages,
  }) {
    final defaultOptions = OllamaChatOptions().toMap();
    final chatOptions = chat.options.toMap();

    // Only include parameters that differ from the defaults.
    final nonDefaultParameters = <String, dynamic>{};
    chatOptions.forEach((key, value) {
      if (defaultOptions[key] != value) {
        nonDefaultParameters[key] = value;
      }
    });

    return ApiCreateRequest(
      model: model,
      from: chat.model,
      system: chat.systemPrompt,
      parameters: nonDefaultParameters.isNotEmpty ? nonDefaultParameters : null,
      messages: messages != null && messages.isNotEmpty ? messages : null,
    );
  }

  Future<Map<String, dynamic>> toJson() async {
    return {
      'model': model,
      'from': from,
      if (system != null && system!.isNotEmpty) 'system': system,
      if (parameters != null) 'parameters': parameters,
      if (messages != null) 'messages': await Future.wait(messages!.map((m) => m.toChatJson())),
      'stream': stream,
    };
  }
}
