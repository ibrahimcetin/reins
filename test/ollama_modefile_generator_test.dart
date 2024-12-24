import 'package:reins/Models/ollama_chat.dart';
import 'package:reins/Models/ollama_message.dart';
import 'package:test/test.dart';
import 'package:reins/Services/ollama_modelfile_generator.dart';

void main() {
  final generator = OllamaModelfileGenerator();

  test('Test generate modelfile from empty chat', () async {
    final chat = OllamaChat(
      model: 'llama3.2:latest',
      systemPrompt:
          'You are Mario from super mario bros, acting as an assistant.',
      options: OllamaChatOptions(),
      title: 'New Chat',
    );

    final result = await generator.generate(chat, []);

    expect(result,
        'FROM llama3.2:latest\nSYSTEM """You are Mario from super mario bros, acting as an assistant."""\n');
  });

  test('Test generate modelfile from chat with options', () async {
    final chat = OllamaChat(
      model: 'llama3.2:latest',
      systemPrompt:
          'You are Mario from super mario bros, acting as an assistant.',
      options: OllamaChatOptions()..temperature = 0.5,
      title: 'New Chat',
    );

    final result = await generator.generate(chat, []);

    expect(result,
        'FROM llama3.2:latest\nSYSTEM """You are Mario from super mario bros, acting as an assistant."""\nPARAMETER temperature 0.5\n');
  });

  test('Test generate modelfile from chat with messages', () async {
    final chat = OllamaChat(
      model: 'llama3.2:latest',
      systemPrompt:
          'You are Mario from super mario bros, acting as an assistant.',
      options: OllamaChatOptions()..temperature = 0.5,
      title: 'New Chat',
    );
    final messages = [
      OllamaMessage('Hello!', role: OllamaMessageRole.user),
      OllamaMessage('How can I help you?', role: OllamaMessageRole.assistant),
    ];

    final result = await generator.generate(chat, messages);

    expect(result,
        'FROM llama3.2:latest\nSYSTEM """You are Mario from super mario bros, acting as an assistant."""\nPARAMETER temperature 0.5\nMESSAGE user Hello!\nMESSAGE assistant How can I help you?\n');
  });

  test('Test generate modelfile with all configured options', () async {
    final options = OllamaChatOptions()
      ..mirostat = 1
      ..mirostatEta = 0.2
      ..mirostatTau = 4.0
      ..contextSize = 1024
      ..repeatLastN = 32
      ..repeatPenalty = 1.2
      ..temperature = 0.5
      ..seed = 42
      ..tailFreeSampling = 0.9
      ..maxTokens = 100
      ..topK = 50
      ..topP = 0.6
      ..minP = 0.1;

    final chat = OllamaChat(
      model: 'llama3.2:latest:latest',
      systemPrompt:
          'You are Mario from super mario bros, acting as an assistant.',
      options: options,
      title: 'New Chat',
    );
    final messages = [
      OllamaMessage('Hello!', role: OllamaMessageRole.user),
      OllamaMessage('How can I help you?', role: OllamaMessageRole.assistant),
    ];

    final result = await generator.generate(chat, messages);

    expect(result,
        'FROM llama3.2:latest:latest\nSYSTEM """You are Mario from super mario bros, acting as an assistant."""\nPARAMETER mirostat 1\nPARAMETER mirostat_eta 0.2\nPARAMETER mirostat_tau 4.0\nPARAMETER num_ctx 1024\nPARAMETER repeat_last_n 32\nPARAMETER repeat_penalty 1.2\nPARAMETER temperature 0.5\nPARAMETER seed 42\nPARAMETER tfs_z 0.9\nPARAMETER num_predict 100\nPARAMETER top_k 50\nPARAMETER top_p 0.6\nPARAMETER min_p 0.1\nMESSAGE user Hello!\nMESSAGE assistant How can I help you?\n');
  });
}
