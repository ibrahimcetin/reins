import 'package:flutter/material.dart';
import 'package:reins/Constants/constants.dart';
import 'package:reins/Widgets/flexible_text.dart';

class OllamaBottomSheetHeader extends StatelessWidget {
  final String title;

  const OllamaBottomSheetHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(AppConstants.appIconPng, height: 48),
          ),
        ),
        FlexibleText(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
