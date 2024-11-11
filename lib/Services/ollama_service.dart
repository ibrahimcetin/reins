import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ollama_chat/Models/ollama_message.dart';

class OllamaService {
  /// The base URL for the Ollama service API.
  ///
  /// This URL is used as the root endpoint for all network requests
  /// made by the Ollama service. It should be set to the base address
  /// of the API server.
  ///
  /// The default value is "http://localhost:11434".
  final String baseUrl;

  /// The model used to generate messages.
  ///
  /// Example: "llama3.2-vision:latest"
  final String model;

  /// The headers to include in all network requests.
  final headers = {'Content-Type': 'application/json'};

  /// Creates a new instance of the Ollama service.
  OllamaService({required this.model, String? baseUrl})
      : baseUrl = baseUrl ?? "http://localhost:11434";

  /// Generates an OllamaMessage.
  ///
  /// This method is responsible for generating an instance of
  /// [OllamaMessage] based on the provided prompt and options.
  ///
  /// [prompt] is the input string used to generate the message.
  /// [options] is a map of additional options that can be used to
  /// customize the generation process. It defaults to an empty map.
  ///
  /// Returns a [Future] that completes with an [OllamaMessage].
  Future<OllamaMessage> generate(
    String prompt, {
    Map<String, dynamic> options = const {},
  }) async {
    final url = Uri.parse("$baseUrl/api/generate");

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        "model": model,
        "prompt": prompt,
        "stream": false, // TODO: Implement streaming
        "options": options,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return OllamaMessage.fromJson(jsonBody);
    } else {
      throw Exception("Failed to generate message");
    }
  }

  /// Sends a chat message to the Ollama service and returns the response.
  ///
  /// This method takes a message and sends it to the Ollama service, which
  /// processes the message and returns a response. The response is then
  /// encapsulated in an [OllamaMessage] object.
  ///
  /// Returns an [OllamaMessage] containing the response from the Ollama service.
  ///
  /// Throws an [Exception] if there is an error during the communication with
  /// the Ollama service.
  Future<OllamaMessage> chat(
    List<OllamaMessage> messages, {
    Map<String, dynamic> options = const {},
  }) async {
    final url = Uri.parse("$baseUrl/api/chat");

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        "model": model,
        "messages": messages.map((m) => m.toChatJson()).toList(),
        "stream": false, // TODO: Implement streaming
        "options": options,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return OllamaMessage.fromJson(jsonBody);
    } else {
      throw Exception("Failed to chat");
    }
  }
}
