/// Model capabilities extracted from /api/show response
class ModelCapabilities {
  final bool completion;
  final bool vision;
  final bool tools;
  final bool embedding;
  final bool thinking;

  const ModelCapabilities({
    this.completion = false,
    this.vision = false,
    this.tools = false,
    this.embedding = false,
    this.thinking = false,
  });

  /// Creates capabilities from the raw capabilities list from /api/show
  factory ModelCapabilities.fromList(List<String> capabilities) {
    return ModelCapabilities(
      completion: capabilities.contains('completion'),
      vision: capabilities.contains('vision'),
      tools: capabilities.contains('tools'),
      embedding: capabilities.contains('embedding'),
      thinking: capabilities.contains('thinking'),
    );
  }

  @override
  String toString() {
    final caps = <String>[];
    if (completion) caps.add('completion');
    if (vision) caps.add('vision');
    if (tools) caps.add('tools');
    if (embedding) caps.add('embedding');
    if (thinking) caps.add('thinking');
    return 'ModelCapabilities(${caps.join(', ')})';
  }
}
