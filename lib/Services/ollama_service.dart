import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:ollama_chat/Models/ollama_model.dart';

class OllamaService {
  /// The base URL for the Ollama service API.
  ///
  /// This URL is used as the root endpoint for all network requests
  /// made by the Ollama service. It should be set to the base address
  /// of the API server.
  ///
  /// The default value is "http://localhost:11434".
  String _baseUrl;
  get baseUrl => _baseUrl;
  set baseUrl(value) => _baseUrl = value ?? "http://localhost:11434";

  /// The headers to include in all network requests.
  final headers = {'Content-Type': 'application/json'};

  /// Creates a new instance of the Ollama service.
  OllamaService({String? baseUrl})
      : _baseUrl = baseUrl ?? "http://localhost:11434";

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
    required String model,
    Map<String, dynamic> options = const {},
  }) async {
    final url = Uri.parse("$baseUrl/api/generate");

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        "model": model,
        "prompt": prompt,
        "options": options,
        "stream": false,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return OllamaMessage.fromJson(jsonBody);
    } else {
      throw Exception("Failed to generate message");
    }
  }

  Stream<OllamaMessage> generateStream(
    String prompt, {
    required String model,
    Map<String, dynamic> options = const {},
  }) async* {
    final url = Uri.parse("$baseUrl/api/generate");

    final request = http.Request("POST", url);
    request.headers.addAll(headers);
    request.body = json.encode({
      "model": model,
      "prompt": prompt,
      "options": options,
      "stream": true,
    });

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      await for (final message in _processStream(response.stream)) {
        yield message;
      }
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
    required String model,
    Map<String, dynamic> options = const {},
  }) async {
    final url = Uri.parse("$baseUrl/api/chat");

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        "model": model,
        "messages": messages.map((m) => m.toChatJson()).toList(),
        "options": options,
        "stream": false,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return OllamaMessage.fromJson(jsonBody);
    } else {
      throw Exception("Failed to chat");
    }
  }

  Stream<OllamaMessage> chatStream(
    List<OllamaMessage> messages, {
    required String model,
    Map<String, dynamic> options = const {},
  }) async* {
    final url = Uri.parse("$baseUrl/api/chat");

    final request = http.Request("POST", url);
    request.headers.addAll(headers);
    request.body = json.encode({
      "model": model,
      "messages": messages.map((m) => m.toChatJson()).toList(),
      "options": options,
      "stream": true,
    });

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      await for (final message in _processStream(response.stream)) {
        yield message;
      }
    } else {
      throw Exception("Failed to chat");
    }
  }

  Stream<OllamaMessage> _processStream(Stream stream) async* {
    // Buffer to store the incomplete JSON object. This is necessary because
    // the Ollama service may send partial JSON objects in a single response.
    // We need to buffer the partial JSON objects and combine them to form
    // complete JSON objects.
    String buffer = '';

    await for (var chunk in stream.transform(utf8.decoder)) {
      chunk = buffer + chunk;
      buffer = '';

      // Split the chunk into lines and parse each line as JSON. This is
      // necessary because the Ollama service may send multiple JSON objects
      // in a single response.
      final lines = LineSplitter.split(chunk);

      for (var line in lines) {
        try {
          final jsonBody = json.decode(line);
          yield OllamaMessage.fromJson(jsonBody);
        } catch (_) {
          buffer = line;
        }
      }
    }
  }

  Future<List<OllamaModel>> listModels() async {
    final url = Uri.parse("$baseUrl/api/tags");

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return List<OllamaModel>.from(
        jsonBody["models"].map((m) => OllamaModel.fromJson(m)),
      );
    } else {
      throw Exception("Failed to list models");
    }
  }
}
