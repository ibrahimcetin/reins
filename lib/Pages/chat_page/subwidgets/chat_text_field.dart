import 'package:flutter/material.dart';

class ChatTextField extends StatefulWidget {
  final TextEditingController? controller;
  final void Function(String)? onChanged;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const ChatTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  static final _textFieldBucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller?.text = _readTextFieldState();
      widget.onChanged?.call(widget.controller?.text ?? '');
    });
  }

  @override
  void deactivate() {
    // Write the latest text to the bucket
    _writeTextFieldState(widget.controller?.text ?? '');

    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        labelText: 'Prompt',
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
      ),
      minLines: 1,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      onTapOutside: (PointerDownEvent event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  }

  String _readTextFieldState() {
    return _textFieldBucket.readState(context, identifier: widget.key) ?? '';
  }

  void _writeTextFieldState(String text) {
    if (widget.key == null) return;

    if (widget.key is ValueKey && (widget.key as ValueKey).value == null) {
      return;
    }

    _textFieldBucket.writeState(context, text, identifier: widget.key);
  }
}
