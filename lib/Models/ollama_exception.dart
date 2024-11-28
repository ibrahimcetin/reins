class OllamaException implements Exception {
  final String message;

  OllamaException(this.message);

  @override
  String toString() {
    return message;
  }
}
