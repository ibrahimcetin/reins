import 'package:flutter/material.dart';
import 'package:reins/Utils/border_painter.dart';

class ChatBubbleMenu extends StatefulWidget {
  final Widget child;
  final List<Widget> menuChildren;

  const ChatBubbleMenu({
    super.key,
    required this.child,
    required this.menuChildren,
  });

  @override
  State<ChatBubbleMenu> createState() => _ChatBubbleMenuState();
}

class _ChatBubbleMenuState extends State<ChatBubbleMenu> {
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
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open(position: details.localPosition);
            }
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
