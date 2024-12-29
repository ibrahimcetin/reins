import 'dart:io';

import 'package:flutter/material.dart';
import 'package:reins/Widgets/chat_image.dart';

class ChatAttachmentImage extends StatelessWidget {
  final File imageFile;
  final Function(File) onRemove;

  const ChatAttachmentImage({
    super.key,
    required this.imageFile,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ChatImage(
          image: FileImage(imageFile),
          height: MediaQuery.of(context).size.height * 0.15,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: () => onRemove(imageFile),
            child: Icon(
              Icons.close,
              color: Colors.white,
              shadows: [BoxShadow(blurRadius: 10)],
            ),
          ),
        ),
      ],
    );
  }
}
