import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:reins/Models/ollama_chat.dart';
import 'package:reins/Models/ollama_exception.dart';
import 'package:reins/Models/ollama_message.dart';
import 'package:reins/Models/ollama_model.dart';
import 'package:reins/Services/ollama_modelfile_generator.dart';

class OllamaService {
  /// The base URL for the Ollama service API.
  ///
  /// This URL is used as the root endpoint for all network requests
  /// made by the Ollama service. It should be set to the base address
  /// of the API server.
  ///
  /// The default value is "http://localhost:11434".
  String _baseUrl;
  String get baseUrl => _baseUrl;
  set baseUrl(String? value) => _baseUrl = value ?? "http://localhost:11434";

  /// The headers to include in all network requests.
  final headers = {'Content-Type': 'application/json'};

  /// The modelfile generator used to generate modelfiles for the Ollama service.
  static final _modelfileGenerator = OllamaModelfileGenerator();

  /// Creates a new instance of the Ollama service.
  OllamaService({String? baseUrl})
      : _baseUrl = baseUrl ?? "http://localhost:11434";

  /// Constructs a URL by resolving the provided path against the base URL.
  Uri constructUrl(String path) {
    final baseUri = Uri.parse(baseUrl);

    // Split the base URI path into segments, filtering out empty strings
    final segments = baseUri.pathSegments.where((s) => s.isNotEmpty).toList();

    // Split the provided path into segments, filtering out empty strings
    final extraSegments = path.split('/').where((s) => s.isNotEmpty).toList();

    // Combine both sets of segments and create a new URI
    return baseUri.replace(pathSegments: [...segments, ...extraSegments]);
  }

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
    required OllamaChat chat,
  }) async {
    final url = constructUrl("/api/generate");

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        "model": chat.model,
        "prompt": prompt,
        "system": chat.systemPrompt,
        "options": chat.options.toMap(),
        "stream": false,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return OllamaMessage.fromJson(jsonBody);
    } else if (response.statusCode == 404) {
      throw OllamaException("${chat.model} not found on the server.");
    } else if (response.statusCode == 500) {
      throw OllamaException("Internal server error.");
    } else {
      throw OllamaException("Something went wrong.");
    }
  }

  Stream<OllamaMessage> generateStream(
    String prompt, {
    required OllamaChat chat,
  }) async* {
    final url = constructUrl('/api/generate');

    final request = http.Request("POST", url);
    request.headers.addAll(headers);
    request.body = json.encode({
      "model": chat.model,
      "prompt": prompt,
      "system": chat.systemPrompt,
      "options": chat.options.toMap(),
      "stream": true,
    });

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      await for (final message in _processStream(response.stream)) {
        yield message;
      }
    } else if (response.statusCode == 404) {
      throw OllamaException("${chat.model} not found on the server.");
    } else if (response.statusCode == 500) {
      throw OllamaException("Internal server error.");
    } else {
      throw OllamaException("Something went wrong.");
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
    required OllamaChat chat,
  }) async {
    final url = constructUrl("/api/chat");

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        "model": chat.model,
        "messages":
            await _prepareMessagesWithSystemPrompt(messages, chat.systemPrompt),
        "options": chat.options.toMap(),
        "stream": false,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return OllamaMessage.fromJson(jsonBody);
    } else if (response.statusCode == 404) {
      throw OllamaException("${chat.model} not found on the server.");
    } else if (response.statusCode == 500) {
      throw OllamaException("Internal server error.");
    } else {
      throw OllamaException("Something went wrong.");
    }
  }

  Stream<OllamaMessage> chatStream(
    List<OllamaMessage> messages, {
    required OllamaChat chat,
  }) async* {
    final url = constructUrl('/api/chat');

    final request = http.Request("POST", url);
    request.headers.addAll(headers);
    request.body = json.encode({
      "model": chat.model,
      "messages":
          await _prepareMessagesWithSystemPrompt(messages, chat.systemPrompt),
      "options": chat.options.toMap(),
      "stream": true,
    });

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      await for (final message in _processStream(response.stream)) {
        yield message;
      }
    } else if (response.statusCode == 404) {
      throw OllamaException("${chat.model} not found on the server.");
    } else if (response.statusCode == 500) {
      throw OllamaException("Internal server error.");
    } else {
      throw OllamaException("Something went wrong.");
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

  // Serializes chat messages with a system prompt.
  Future<List<Map<String, dynamic>>> _prepareMessagesWithSystemPrompt(
    List<OllamaMessage> messages,
    String? systemPrompt,
  ) async {
    final jsonMessages =
        await Future.wait(messages.map((m) async => await m.toChatJson()));

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      final sp = OllamaMessage(systemPrompt, role: OllamaMessageRole.system);
      jsonMessages.insert(0, await sp.toChatJson());
    }

    return jsonMessages;
  }

  /// Lists the available models on the Ollama service.
  Future<List<OllamaModel>> listModels() async {
    final url = constructUrl("/api/tags");

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return List<OllamaModel>.from(
        jsonBody["models"].map((m) => OllamaModel.fromJson(m)),
      );
    } else if (response.statusCode == 500) {
      throw OllamaException("Internal server error.");
    } else {
      throw OllamaException("Something went wrong.");
    }
  }

  Future<void> createModel(
    String model, {
    required OllamaChat chat,
    List<OllamaMessage>? messages,
  }) async {
    final url = constructUrl("/api/create");

    final modelfile = await _modelfileGenerator.generate(chat, messages ?? []);

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        "model": model,
        "modelfile": modelfile,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 500) {
      throw OllamaException("Internal server error.");
    } else {
      throw OllamaException("Something went wrong.");
    }
  }

  Future<void> deleteModel(String model) async {
    final url = constructUrl("/api/delete");

    final response = await http.delete(
      url,
      headers: headers,
      body: json.encode({"model": model}),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw OllamaException("$model not found on the server.");
    } else if (response.statusCode == 500) {
      throw OllamaException("Internal server error.");
    } else {
      throw OllamaException("Something went wrong.");
    }
  }
}
