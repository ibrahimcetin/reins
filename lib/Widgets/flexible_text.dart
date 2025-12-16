import 'package:flutter/material.dart';

/// A [Text] widget wrapped in [Flexible] for use inside [Row] or [Column].
///
/// Prevents text overflow by allowing text to wrap up to [maxLines]
/// and truncating with ellipsis if needed.
class FlexibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextScaler? textScaler;

  const FlexibleText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.textScaler,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        textScaler: textScaler,
      ),
    );
  }
}
