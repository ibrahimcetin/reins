import 'package:flutter/material.dart';
import 'package:reins/Models/chat_preset.dart';

class ChatAttachmentPreset extends StatelessWidget {
  final ChatPreset preset;
  final Function() onPressed;

  const ChatAttachmentPreset({
    super.key,
    required this.preset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(preset.title, style: Theme.of(context).textTheme.titleSmall),
            Text(
              preset.subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
