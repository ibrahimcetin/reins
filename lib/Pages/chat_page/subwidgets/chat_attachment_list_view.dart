import 'dart:io';

import 'package:flutter/material.dart';
import 'package:reins/Widgets/chat_image.dart';

class ChatAttachmentListView extends StatelessWidget {
  final List<File> imageFiles;
  final Function(File) onRemove;

  const ChatAttachmentListView({
    super.key,
    required this.imageFiles,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      physics: const ClampingScrollPhysics(),
      itemCount: imageFiles.length,
      itemBuilder: (context, index) {
        final imageFile = imageFiles[index];

        return Stack(
          children: [
            ChatImage(image: FileImage(imageFile)),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
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
      },
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(width: 8.0);
      },
    );
  }
}
