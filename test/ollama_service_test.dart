import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:reins/Models/ollama_chat.dart';
import 'package:reins/Services/ollama_service.dart';
import 'package:reins/Models/ollama_message.dart';
import 'package:test/test.dart';

void main() {
  final service = OllamaService();
  const model = "llama3.2:latest";

  final chat = OllamaChat(
    model: model,
    title: "Test chat",
    systemPrompt:
        "You are a pirate who don't talk too much, acting as an assistant.",
  );
  chat.options.temperature = 0;
  chat.options.seed = 1453;

  const ollamaChatResponseText =
      '''*nods* Alright then...\n\n```dart\nprint('Hello, world!');\n```\n\n*hands over a piece of parchment with the code on it*''';

  final assetsPath = path.join(Directory.current.path, 'test', 'assets');
  final imageFile = File(path.join(assetsPath, 'images', 'ollama.png'));

  final chatForImage = OllamaChat(
    model: 'llama3.2-vision:latest',
    title: "Test chat",
    systemPrompt:
        "You are a pirate who don't talk too much, acting as an assistant.",
  );
  chatForImage.options.temperature = 0;
  chatForImage.options.seed = 1453;

  test("Test Ollama generate endpoint (non-stream)", () async {
    final message = await service.generate("Hello", chat: chat);

    expect(message.content, "How can I assist you today?");
  });

  test("Test Ollama generate endpoint (stream)", () async {
    final stream = service.generateStream("Hello", chat: chat);

    var ollamaMessage = "";
    await for (final message in stream) {
      ollamaMessage += message.content;
    }

    expect(ollamaMessage, "How can I assist you today?");
  });

  test("Test Ollama chat endpoint (non-stream)", () async {
    final message = await service.chat(
      [
        OllamaMessage(
          "Hello!",
          role: OllamaMessageRole.user,
        ),
        OllamaMessage(
          "*grunts* Ye be lookin' fer somethin', matey?",
          role: OllamaMessageRole.assistant,
        ),
        OllamaMessage(
          "Write me a dart code which prints 'Hello, world!'.",
          role: OllamaMessageRole.user,
        ),
      ],
      chat: chat,
    );

    expect(message.content, ollamaChatResponseText);
  });

  test("Test Ollama chat endpoint (stream)", () async {
    final stream = service.chatStream(
      [
        OllamaMessage(
          "Hello!",
          role: OllamaMessageRole.user,
        ),
        OllamaMessage(
          "*grunts* Ye be lookin' fer somethin', matey?",
          role: OllamaMessageRole.assistant,
        ),
        OllamaMessage(
          "Write me a dart code which prints 'Hello, world!'.",
          role: OllamaMessageRole.user,
        ),
      ],
      chat: chat,
    );

    List<String> ollamaMessages = [];
    await for (final message in stream) {
      ollamaMessages.add(message.content);
    }

    expect(ollamaMessages.join(), ollamaChatResponseText);
  });

  test('Test Ollama chat endpoint with images (stream)', () async {
    final stream = service.chatStream(
      [
        OllamaMessage(
          "Hello!, What is in the image?",
          images: [imageFile],
          role: OllamaMessageRole.user,
        ),
      ],
      chat: chatForImage,
    );

    List<String> ollamaMessages = [];
    await for (final message in stream) {
      ollamaMessages.add(message.content);
    }

    final message = ollamaMessages.join();

    expect(
      message,
      '* The image features a simple black and white line drawing of an alpaca\'s head.\n'
      '* The alpaca has two small ears on top of its head, large eyes, and a small nose.\n'
      '* Its mouth is closed, giving it a calm expression.',
    );
  }, timeout: Timeout.none);

  test("Test Ollama tags endpoint", () async {
    final models = await service.listModels();

    expect(models, isNotEmpty);
    expect(models.map((e) => e.model).contains(model), true);
  });

  test("Test Ollama create endpoint without messages", () async {
    await service.createModel("test_model", chat: chat);
  });

  test("Test Ollama create endpoint", () async {
    final messages = [
      OllamaMessage(
        "Hello!",
        role: OllamaMessageRole.user,
      ),
      OllamaMessage(
        "*grunts* Ye be lookin' fer somethin', matey?",
        role: OllamaMessageRole.assistant,
      ),
      OllamaMessage(
        "Write me a dart code which prints 'Hello, world!'.",
        role: OllamaMessageRole.user,
      ),
    ];

    await service.createModel(
      "test_model_with_messages",
      chat: chat,
      messages: messages,
    );
  });

  test("Test Ollama delete endpoint", () async {
    await service.deleteModel("test_model:latest");

    await service.deleteModel("test_model_with_messages:latest");
  });

  test("Test constructUrl with various base URLs", () {
    // Test with trailing slash
    var service = OllamaService(baseUrl: "http://localhost:11434/");
    expect(service.constructUrl("/api/chat").toString(),
        "http://localhost:11434/api/chat");
    expect(service.constructUrl("api/generate").toString(),
        "http://localhost:11434/api/generate");

    // Test without trailing slash
    service = OllamaService(baseUrl: "http://localhost:11434");
    expect(service.constructUrl("/api/tags").toString(),
        "http://localhost:11434/api/tags");
    expect(service.constructUrl("api/models").toString(),
        "http://localhost:11434/api/models");

    // Test with path component
    service = OllamaService(baseUrl: "http://localhost:11434/ollama");
    expect(service.constructUrl("/api/chat").toString(),
        "http://localhost:11434/ollama/api/chat");
    expect(service.constructUrl("api/generate").toString(),
        "http://localhost:11434/ollama/api/generate");

    // Test with path component and trailing slash
    service = OllamaService(baseUrl: "http://localhost:11434/ollama/");
    expect(service.constructUrl("/api/chat").toString(),
        "http://localhost:11434/ollama/api/chat");
    expect(service.constructUrl("api/generate").toString(),
        "http://localhost:11434/ollama/api/generate");

    // Test with IP address
    service = OllamaService(baseUrl: "http://192.168.1.100:11434");
    expect(service.constructUrl("/api/chat").toString(),
        "http://192.168.1.100:11434/api/chat");
    expect(service.constructUrl("api/generate").toString(),
        "http://192.168.1.100:11434/api/generate");

    // Test with subdomain
    service = OllamaService(baseUrl: "http://ollama.mydomain.com/");
    expect(service.constructUrl("/api/chat").toString(),
        "http://ollama.mydomain.com/api/chat");

    // Test with HTTPS
    service = OllamaService(baseUrl: "https://ollama.mydomain.com");
    expect(service.constructUrl("/api/chat").toString(),
        "https://ollama.mydomain.com/api/chat");

    // Test setting baseUrl after initialization
    service = OllamaService();
    service.baseUrl = "http://newhost:11434/";
    expect(service.constructUrl("/api/chat").toString(),
        "http://newhost:11434/api/chat");
  });
}
