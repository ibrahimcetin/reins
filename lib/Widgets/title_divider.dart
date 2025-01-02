import 'package:flutter/material.dart';

class TitleDivider extends StatelessWidget {
  final String title;

  const TitleDivider({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(title),
        ),
        Expanded(child: Divider())
      ],
    );
  }
}
