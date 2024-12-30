import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reins/Models/ollama_message.dart';
import 'package:reins/Providers/chat_provider.dart';

import 'chat_bubble_bottom_sheet.dart';

class ChatBubbleActions {
  final OllamaMessage message;

  ChatBubbleActions(this.message);

  void handleCopy() {
    Clipboard.setData(ClipboardData(text: message.content));
  }

  void handleSelectText(BuildContext context) {
    showModalBottomSheet(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      isScrollControlled: true,
      builder: (context) {
        return ChatBubbleBottomSheet(
          title: 'Select Text',
          child: SelectableText(
            message.content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      },
    );
  }

  void handleRegenerate(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    chatProvider.regenerateMessage(message);
  }

  void handleEdit(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        String textFieldText = message.content;

        return ChatBubbleBottomSheet(
          title: 'Edit Message',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (textFieldText.isNotEmpty) {
                  await chatProvider.updateMessage(
                    message,
                    newContent: textFieldText,
                  );
                  if (context.mounted) Navigator.pop(context, textFieldText);
                }
              },
              child: const Text('Save'),
            ),
          ],
          child: TextFormField(
            initialValue: textFieldText,
            onChanged: (value) => textFieldText = value,
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
        );
      },
    );
  }

  void handleDelete(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Message?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await chatProvider.deleteMessage(message);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
