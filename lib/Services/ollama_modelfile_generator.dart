import '../Models/ollama_chat.dart';
import '../Models/ollama_message.dart';

class OllamaModelfileGenerator {
  static final Map<String, dynamic> defaultOptions = OllamaChatOptions().toMap();

  Future<String> generate(OllamaChat chat, List<OllamaMessage> messages) async {
    final buffer = StringBuffer();

    // Write FROM instruction
    buffer.writeln('FROM ${chat.model}');

    // Write SYSTEM message if available
    if (chat.systemPrompt != null) {
      buffer.writeln('SYSTEM """${chat.systemPrompt}"""');
    }

    // Write PARAMETERS
    chat.options.toMap().forEach((key, value) {
      if (defaultOptions[key] != value) {
        buffer.writeln('PARAMETER $key $value');
      }
    });

    // Write MESSAGE history
    for (var message in messages) {
      final role = message.role.name;
      final content = message.content;
      buffer.writeln('MESSAGE $role $content');
    }

    return buffer.toString();
  }
}
