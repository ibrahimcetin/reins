import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ollama_chat/Constants/constants.dart';

class ChatEmpty extends StatelessWidget {
  final Widget child;

  const ChatEmpty({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          AppConstants.appIconSvg,
          height: 48,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),
        child,
      ],
    );
  }
}
