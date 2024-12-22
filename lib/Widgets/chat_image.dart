import 'package:flutter/material.dart';

class ChatImage extends StatelessWidget {
  final ImageProvider image;
  final double aspectRatio;
  final double? height;
  final double? width;

  const ChatImage({
    super.key,
    required this.image,
    this.aspectRatio = 1.0,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Image(
            image: image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        ),
      ),
    );
  }
}
