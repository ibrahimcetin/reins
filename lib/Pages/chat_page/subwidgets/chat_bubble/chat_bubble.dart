import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:reins/Models/ollama_message.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'chat_bubble_actions.dart';
import 'chat_bubble_image.dart';
import 'chat_bubble_menu.dart';
import 'chat_bubble_think_block.dart';

class ChatBubble extends StatelessWidget {
  final OllamaMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final actions = ChatBubbleActions(message);

    return ChatBubbleMenu(
      menuChildren: [
        MenuItemButton(
          onPressed: actions.handleCopy,
          leadingIcon: Icon(Icons.copy_outlined),
          child: const Text('Copy'),
        ),
        MenuItemButton(
          onPressed: () => actions.handleSelectText(context),
          leadingIcon: Icon(Icons.select_all_outlined),
          child: const Text('Select Text'),
        ),
        MenuItemButton(
          onPressed: () => actions.handleRegenerate(context),
          leadingIcon: Icon(Icons.refresh_outlined),
          child: const Text('Regenerate'),
        ),
        Divider(),
        MenuItemButton(
          onPressed: () => actions.handleEdit(context),
          closeOnActivate: false,
          leadingIcon: Icon(Icons.edit_outlined),
          child: const Text('Edit'),
        ),
        MenuItemButton(
          onPressed: () => actions.handleDelete(context),
          leadingIcon: Icon(Icons.delete_outline),
          child: const Text('Delete'),
        ),
      ],
      child: _ChatBubbleBody(message: message),
    );
  }
}

class _ChatBubbleBody extends StatelessWidget {
  final OllamaMessage message;

  const _ChatBubbleBody({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      child: Column(
        spacing: 8,
        crossAxisAlignment: bubbleAlignment,
        children: [
          // If the message has an image attachment, display it
          if (message.images != null && message.images!.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.images!
                  .map((imageFile) => ChatBubbleImage(imageFile: imageFile))
                  .toList(),
            ),
          Container(
            padding: isSentFromUser ? const EdgeInsets.all(10.0) : null,
            constraints: BoxConstraints(
              maxWidth: isSentFromUser
                  ? MediaQuery.of(context).size.width * 0.8
                  : double.infinity,
            ),
            decoration: BoxDecoration(
              color: isSentFromUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                message.thinking != null
                  ? ThinkBlockSyntax(
                      content: MarkdownBody(
                        data: message.thinking,
                        selectable: true,
                        softLineBreak: true,
                        styleSheet: MarkdownStyleSheet(
                          textScaler: TextScaler.linear(1.18),
                          code: GoogleFonts.sourceCodePro(),
                        ),
                        extensionSet: md.ExtensionSet(
                          <md.InlineSyntax>[
                            md.EmojiSyntax(),
                            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes
                          ],
                        ),
                        onTapLink: (text, href, title) => launchUrlString(href!),
                      ),
                    )
                  : null,
                MarkdownBody(
                  data: message.content,
                  selectable: true,
                  softLineBreak: true,
                  styleSheet: MarkdownStyleSheet(
                    textScaler: TextScaler.linear(1.18),
                    code: GoogleFonts.sourceCodePro(),
                  ),
                  builders: {'think': ThinkBlockBuilder()},
                  extensionSet: md.ExtensionSet(
                    <md.BlockSyntax>[
                      ThinkBlockSyntax(),
                      ...md.ExtensionSet.gitHubFlavored.blockSyntaxes
                    ],
                    <md.InlineSyntax>[
                      md.EmojiSyntax(),
                      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes
                    ],
                  ),
                  onTapLink: (text, href, title) => launchUrlString(href!),
                ),
              ],
            ),
          ),
          Text(
            TimeOfDay.fromDateTime(message.createdAt.toLocal()).format(context),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns true if the message is sent from the user.
  bool get isSentFromUser => message.role == OllamaMessageRole.user;

  /// Returns the alignment of the bubble.
  ///
  /// If the message is sent from the user, the alignment is [Alignment.centerRight].
  /// Otherwise, the alignment is [Alignment.centerLeft].
  CrossAxisAlignment get bubbleAlignment =>
      isSentFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
}
