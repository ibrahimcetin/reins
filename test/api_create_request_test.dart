import 'package:reins/Models/api/create_request.dart';
import 'package:reins/Models/ollama_chat.dart';
import 'package:reins/Models/ollama_message.dart';
import 'package:test/test.dart';

void main() {
  test('fromChat with default options produces no parameters', () async {
    final chat = OllamaChat(
      model: 'llama3.2:latest',
      systemPrompt: 'You are Mario from super mario bros, acting as an assistant.',
      options: OllamaChatOptions(),
      title: 'New Chat',
    );

    final request = ApiCreateRequest.fromChat(
      'my-model',
      chat: chat,
    );

    final json = await request.toJson();

    expect(json['model'], 'my-model');
    expect(json['from'], 'llama3.2:latest');
    expect(json['system'], 'You are Mario from super mario bros, acting as an assistant.');
    expect(json.containsKey('parameters'), isFalse);
    expect(json.containsKey('messages'), isFalse);
    expect(json['stream'], false);
  });

  test('fromChat with non-default temperature includes only that parameter', () async {
    final chat = OllamaChat(
      model: 'llama3.2:latest',
      systemPrompt: 'You are Mario from super mario bros, acting as an assistant.',
      options: OllamaChatOptions()..temperature = 0.5,
      title: 'New Chat',
    );

    final request = ApiCreateRequest.fromChat(
      'my-model',
      chat: chat,
    );

    final json = await request.toJson();

    expect(json['model'], 'my-model');
    expect(json['from'], 'llama3.2:latest');
    expect(json['system'], 'You are Mario from super mario bros, acting as an assistant.');
    expect(json['parameters'], {'temperature': 0.5});
    expect(json.containsKey('messages'), isFalse);
    expect(json['stream'], false);
  });

  test('fromChat with messages includes them in JSON output', () async {
    final chat = OllamaChat(
      model: 'llama3.2:latest',
      systemPrompt: 'You are Mario from super mario bros, acting as an assistant.',
      options: OllamaChatOptions()..temperature = 0.5,
      title: 'New Chat',
    );
    final messages = [
      OllamaMessage('Hello!', role: OllamaMessageRole.user),
      OllamaMessage('How can I help you?', role: OllamaMessageRole.assistant),
    ];

    final request = ApiCreateRequest.fromChat(
      'my-model',
      chat: chat,
      messages: messages,
    );

    final json = await request.toJson();

    expect(json['model'], 'my-model');
    expect(json['from'], 'llama3.2:latest');
    expect(json['parameters'], {'temperature': 0.5});
    expect(json['messages'], hasLength(2));
    expect(json['messages'][0]['role'], 'user');
    expect(json['messages'][0]['content'], 'Hello!');
    expect(json['messages'][1]['role'], 'assistant');
    expect(json['messages'][1]['content'], 'How can I help you?');
  });

  test('fromChat with all non-default options includes all parameters', () async {
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
      model: 'llama3.2:latest',
      systemPrompt: 'You are Mario from super mario bros, acting as an assistant.',
      options: options,
      title: 'New Chat',
    );
    final messages = [
      OllamaMessage('Hello!', role: OllamaMessageRole.user),
      OllamaMessage('How can I help you?', role: OllamaMessageRole.assistant),
    ];

    final request = ApiCreateRequest.fromChat(
      'my-model',
      chat: chat,
      messages: messages,
    );

    final json = await request.toJson();

    expect(json['parameters'], {
      'mirostat': 1,
      'mirostat_eta': 0.2,
      'mirostat_tau': 4.0,
      'num_ctx': 1024,
      'repeat_last_n': 32,
      'repeat_penalty': 1.2,
      'temperature': 0.5,
      'seed': 42,
      'tfs_z': 0.9,
      'num_predict': 100,
      'top_k': 50,
      'top_p': 0.6,
      'min_p': 0.1,
    });
    expect(json['messages'], hasLength(2));
  });

  test('fromChat with no system prompt omits system from JSON', () async {
    final chat = OllamaChat(
      model: 'llama3.2:latest',
      options: OllamaChatOptions(),
      title: 'New Chat',
    );

    final request = ApiCreateRequest.fromChat(
      'my-model',
      chat: chat,
    );

    final json = await request.toJson();

    expect(json.containsKey('system'), isFalse);
  });

  test('fromChat with empty messages list omits messages', () async {
    final chat = OllamaChat(
      model: 'llama3.2:latest',
      systemPrompt: 'Test prompt',
      options: OllamaChatOptions(),
      title: 'New Chat',
    );

    final request = ApiCreateRequest.fromChat(
      'my-model',
      chat: chat,
      messages: [],
    );

    final json = await request.toJson();

    expect(json.containsKey('messages'), isFalse);
  });
}
