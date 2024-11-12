import 'package:ollama_chat/Services/ollama_service.dart';
import 'package:ollama_chat/Models/ollama_message.dart';
import 'package:test/test.dart';

void main() {
  final service = OllamaService(
    model: "llama3.2-vision:latest",
    // baseUrl: "https://ollama.loca.lt",
  );

  test("Test Ollama generate endpoint", () async {
    final message =
        await service.generate("Hello", options: {"temperature": 0});

    expect(message.content, "How can I assist you today?");
  });

  test("Test Ollama chat endpoint", () async {
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
      options: {"temperature": 0},
    );

    print("Test Ollama chat endpoint message:");
    print(message.content);

    expect(message.content, isNotEmpty);
  });
}
