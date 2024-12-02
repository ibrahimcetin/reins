import 'package:ollama_chat/Models/ollama_chat.dart';
import 'package:ollama_chat/Services/ollama_service.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
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

  test("Test Ollama tags endpoint", () async {
    final models = await service.listModels();

    expect(models, isNotEmpty);
    expect(models.map((e) => e.model).contains(model), true);
  });
}
