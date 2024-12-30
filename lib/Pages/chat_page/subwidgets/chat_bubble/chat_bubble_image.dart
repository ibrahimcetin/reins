import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:reins/Widgets/chat_image.dart';

class ChatBubbleImage extends StatelessWidget {
  final File imageFile;

  const ChatBubbleImage({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return _ChatBubbleImageFullScreen(imageFile: imageFile);
            },
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Hero(
        tag: imageFile.path,
        child: ChatImage(
          image: FileImage(imageFile),
          aspectRatio: 1.5,
          width: max(
            MediaQuery.of(context).size.width * 0.35,
            MediaQuery.of(context).size.height * 0.25,
          ),
        ),
      ),
    );
  }
}

class _ChatBubbleImageFullScreen extends StatelessWidget {
  const _ChatBubbleImageFullScreen({required this.imageFile});

  final File imageFile;

  @override
  Widget build(BuildContext context) {
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
  }
}
