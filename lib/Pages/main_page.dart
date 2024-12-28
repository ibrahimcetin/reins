import 'package:flutter/material.dart';
import 'package:reins/Pages/chat_page/chat_page.dart';
import 'package:reins/Widgets/chat_app_bar.dart';
import 'package:reins/Widgets/chat_drawer.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ReinsMainPage extends StatelessWidget {
  const ReinsMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      return const Scaffold(
        appBar: ChatAppBar(),
        body: SafeArea(child: ChatPage()),
        drawer: ChatDrawer(),
      );
    } else {
      return _ReinsLargeMainPage();
    }
  }
}

class _ReinsLargeMainPage extends StatelessWidget {
  const _ReinsLargeMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            ChatDrawer(),
            Expanded(child: ChatPage()),
          ],
        ),
      ),
    );
  }
}
