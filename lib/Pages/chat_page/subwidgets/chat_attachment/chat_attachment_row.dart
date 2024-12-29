import 'package:flutter/material.dart';

class ChatAttachmentRow extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const ChatAttachmentRow({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      physics: const ClampingScrollPhysics(),
      child: Row(
        spacing: 8.0,
        children: List.generate(
          itemCount,
          (index) => itemBuilder(context, index),
        ),
      ),
    );
  }
}
