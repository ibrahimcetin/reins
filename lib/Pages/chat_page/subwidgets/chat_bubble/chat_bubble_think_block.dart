import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';

class ThinkBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^<think>$');

  @override
  bool canEndBlock(md.BlockParser parser) => false;

  const ThinkBlockSyntax();

  @override
  List<md.Line> parseChildLines(md.BlockParser parser) {
    final childLines = <md.Line>[];

    parser.advance(); // Advance past the opening <think> tag

    while (!parser.isDone) {
      if (parser.current.content == '</think>') {
        parser.advance(); // Advance past the closing </think> tag
        break;
      }

      childLines.add(parser.current);
      parser.advance();
    }

    return childLines;
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final childLines = parseChildLines(parser);

    var content = childLines.map((e) => e.content).join('\n');

    return md.Element('pre', [md.Element.text('think', content)]);
  }
}

class ThinkBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return ThinkBlockWidget(content: element.textContent);
  }
}

class ThinkBlockWidget extends StatefulWidget {
  final String content;

  const ThinkBlockWidget({super.key, required this.content});

  @override
  State<ThinkBlockWidget> createState() => _ThinkBlockWidgetState();
}

class _ThinkBlockWidgetState extends State<ThinkBlockWidget> {
  bool _showingThought = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() => _showingThought = !_showingThought);
          },
          child: Row(
            children: [
              Text('Thought', style: TextStyle(color: _thoughtColor)),
              Icon(_thoughtButtonIcon, color: _thoughtColor),
            ],
          ),
        ),
        if (_showingThought)
          SelectableText(widget.content,
              style: TextStyle(color: _thoughtColor)),
      ],
    );
  }

  IconData get _thoughtButtonIcon =>
      _showingThought ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up;

  Color get _thoughtColor => Theme.of(context).colorScheme.secondary;
}
