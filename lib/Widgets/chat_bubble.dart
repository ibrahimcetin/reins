import 'package:flutter/material.dart';
import 'package:ollama_chat/Models/ollama_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final OllamaMessage message;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Align(
        alignment: bubbleAlignment,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: SelectableText(
            message.content,
            style: TextStyle(color: bubbleTextColor),
          ),
        ),
      ),
      subtitle: Align(
        alignment: bubbleAlignment,
        child: Text(
          TimeOfDay.fromDateTime(message.createdAt.toLocal()).format(context),
        ),
      ),
    );
  }

  /// Returns true if the message is sent from the user.
  bool get isSentFromUser => message.role == OllamaMessageRole.user;

  /// Returns the alignment of the bubble.
  ///
  /// If the message is sent from the user, the alignment is [Alignment.centerRight].
  /// Otherwise, the alignment is [Alignment.centerLeft].
  Alignment get bubbleAlignment =>
      isSentFromUser ? Alignment.centerRight : Alignment.centerLeft;

  /// Returns the color of the bubble.
  Color? get bubbleColor =>
      isSentFromUser ? Colors.blueAccent : Colors.grey[300];

  /// Returns the color of the bubble text.
  Color get bubbleTextColor => isSentFromUser ? Colors.white : Colors.black;
}
