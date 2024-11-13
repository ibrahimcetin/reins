import 'package:ollama_chat/Services/ollama_service.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  final service = OllamaService();
  const model = "llama3.2-vision:latest";

  test("Test Ollama generate endpoint (non-stream)", () async {
    final message = await service.generate(
      "Hello",
      model: model,
      options: {"temperature": 0},
    );

    expect(message.content, "How can I assist you today?");
  });

  test("Test Ollama generate endpoint (stream)", () async {
    final stream = service.generateStream(
      "Hello",
      model: model,
      options: {"temperature": 0},
    );

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
          "You are a pirate who is dart programming expert.",
          role: OllamaMessageRole.system,
        ),
        OllamaMessage(
          "Hello!",
          role: OllamaMessageRole.user,
        ),
        OllamaMessage(
          "It's nice to meet you. Is there something I can help you with or would you like to chat",
          role: OllamaMessageRole.assistant,
        ),
        OllamaMessage(
          "Write me a dart code which prints 'Hello, world!'.",
          role: OllamaMessageRole.user,
        ),
      ],
      model: model,
      options: {"temperature": 0},
    );

    print("Test Ollama chat endpoint message:");
    print(message.content);

    expect(message.content, isNotEmpty);
  });

  test("Test Ollama chat endpoint (stream)", () async {
    final stream = service.chatStream(
      [
        OllamaMessage(
          "You are a pirate who is dart programming expert.",
          role: OllamaMessageRole.system,
        ),
        OllamaMessage(
          "Hello!",
          role: OllamaMessageRole.user,
        ),
        OllamaMessage(
          "It's nice to meet you. Is there something I can help you with or would you like to chat",
          role: OllamaMessageRole.assistant,
        ),
        OllamaMessage(
          "Write me a dart code which prints 'Hello, world!'.",
          role: OllamaMessageRole.user,
        ),
      ],
      model: model,
      options: {"temperature": 0},
    );

    print("Test Ollama chat endpoint message:");

    var ollamaMessage = "";
    await for (final message in stream) {
      stdout.write(message.content);
      stdout.flush();

      ollamaMessage += message.content;
    }

    expect(ollamaMessage, isNotEmpty);
  });
}
