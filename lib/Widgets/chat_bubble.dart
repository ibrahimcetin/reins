import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:reins/Models/ollama_message.dart';
import 'package:reins/Providers/chat_provider.dart';
import 'package:reins/Utils/border_painter.dart';
import 'package:reins/Widgets/chat_bubble_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:reins/Widgets/chat_image.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ChatBubble extends StatelessWidget {
  final OllamaMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _ChatBubbleMenu(
      menuChildren: [
        MenuItemButton(
          onPressed: _handleCopy,
          leadingIcon: Icon(Icons.copy_outlined),
          child: const Text('Copy'),
        ),
        MenuItemButton(
          onPressed: () => _handleSelectText(context),
          leadingIcon: Icon(Icons.select_all_outlined),
          child: const Text('Select Text'),
        ),
        MenuItemButton(
          onPressed: () => _handleRegenerate(context),
          leadingIcon: Icon(Icons.refresh_outlined),
          child: const Text('Regenerate'),
        ),
        Divider(),
        MenuItemButton(
          onPressed: () => _handleEdit(context),
          closeOnActivate: false,
          leadingIcon: Icon(Icons.edit_outlined),
          child: const Text('Edit'),
        ),
        MenuItemButton(
          onPressed: () => _handleDelete(context),
          leadingIcon: Icon(Icons.delete_outline),
          child: const Text('Delete'),
        ),
      ],
      child: _ChatBubbleBody(message: message),
    );
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: message.content));
  }

  void _handleSelectText(BuildContext context) {
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

  void _handleRegenerate(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    chatProvider.regenerateMessage(message);
  }

  void _handleEdit(BuildContext context) {
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

  void _handleDelete(BuildContext context) {
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
                  .map(
                    (imageFile) => _ChatBubbleImage(imageFile: imageFile),
                  )
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
            child: MarkdownBody(
              data: message.content,
              softLineBreak: true,
              styleSheet: MarkdownStyleSheet(
                textScaler: TextScaler.linear(1.18),
                code: GoogleFonts.sourceCodePro(),
              ),
              extensionSet: md.ExtensionSet(
                md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                <md.InlineSyntax>[
                  md.EmojiSyntax(),
                  ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes
                ],
              ),
              onTapLink: (text, href, title) => launchUrlString(href!),
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

class _ChatBubbleImage extends StatelessWidget {
  final File imageFile;

  const _ChatBubbleImage({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(_createRoute());
      },
      child: Hero(
        tag: imageFile.path,
        child: ChatImage(
          image: FileImage(imageFile),
          aspectRatio: 1.5,
          width: MediaQuery.of(context).size.height * 0.2,
        ),
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: PhotoView(
                    imageProvider: FileImage(imageFile),
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.error, color: Colors.red),
                      );
                    },
                    backgroundDecoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: imageFile.path,
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 0,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      shadows: [BoxShadow(blurRadius: 10)],
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _ChatBubbleMenu extends StatefulWidget {
  final Widget child;
  final List<Widget> menuChildren;

  const _ChatBubbleMenu({
    super.key,
    required this.child,
    required this.menuChildren,
  });

  @override
  State<_ChatBubbleMenu> createState() => __ChatBubbleMenuState();
}

class __ChatBubbleMenuState extends State<_ChatBubbleMenu> {
  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: widget.menuChildren,
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () => controller.close(),
          onLongPressStart: (details) {
            controller.open(position: details.localPosition);
          },
          onDoubleTapDown: (details) {
            controller.open(position: details.localPosition);
          },
          onSecondaryTapDown: (details) {
            controller.open(position: details.localPosition);
          },
          child: CustomPaint(
            foregroundPainter: BorderPainter(
              color: controller.isOpen
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface,
              borderRadius: Radius.circular(10.0),
              strokeWidth: 2,
              padding: EdgeInsets.symmetric(horizontal: 10.0),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
      onOpen: () => setState(() {}),
      onClose: () => setState(() {}),
    );
  }
}
