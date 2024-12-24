import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:reins/Models/settings_route_arguments.dart';

class ChatWelcome extends StatelessWidget {
  final CrossFadeState showingState;

  final void Function()? onFirstChildFinished;

  final double secondChildScale;
  final void Function()? onSecondChildScaleEnd;

  const ChatWelcome({
    super.key,
    required this.showingState,
    this.onFirstChildFinished,
    required this.secondChildScale,
    this.onSecondChildScaleEnd,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      crossFadeState: showingState,
      duration: const Duration(milliseconds: 150),
      firstChild: _ChatWelcomeText(
        onFinished: onFirstChildFinished,
      ),
      secondChild: AnimatedScale(
        scale: secondChildScale,
        duration: const Duration(milliseconds: 100),
        onEnd: onSecondChildScaleEnd,
        child: _ChatConfigureServerAddressButton(),
      ),
      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              key: topChildKey,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: topChild,
              ),
            ),
            Positioned(
              key: bottomChildKey,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: bottomChild,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChatWelcomeText extends StatelessWidget {
  final void Function()? onFinished;

  const _ChatWelcomeText({super.key, this.onFinished});

  @override
  Widget build(BuildContext context) {
    return AnimatedTextKit(
      animatedTexts: [
        TyperAnimatedText(
          'Welcome to Ollama Chat!',
          speed: const Duration(milliseconds: 100),
        ),
        TyperAnimatedText(
          'Configure the server address to start.',
          speed: const Duration(milliseconds: 100),
        ),
      ],
      displayFullTextOnTap: true,
      isRepeatingAnimation: false,
      pause: Duration(milliseconds: 1500),
      stopPauseOnTap: true,
      onFinished: onFinished,
    );
  }
}

class _ChatConfigureServerAddressButton extends StatelessWidget {
  const _ChatConfigureServerAddressButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.amber,
      ),
      label: Text('Tap to configure the server address'),
      iconAlignment: IconAlignment.start,
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/settings',
          arguments: SettingsRouteArguments(autoFocusServerAddress: true),
        );
      },
    );
  }
}
