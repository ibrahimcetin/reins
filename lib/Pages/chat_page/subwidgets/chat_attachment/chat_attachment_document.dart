import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:reins/Services/services.dart';

class ChatAttachmentDocument extends StatelessWidget {
  final File documentFile;
  final Function(File) onRemove;

  const ChatAttachmentDocument({
    super.key,
    required this.documentFile,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(documentFile.path);
    final fileService = FileService();
    final icon = fileService.getFileTypeIcon(documentFile);

    return Container(
      width: 120,
      height: MediaQuery.of(context).size.height * 0.15,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: () => onRemove(documentFile),
              child: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}