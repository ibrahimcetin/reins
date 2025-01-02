import 'package:flutter/material.dart';
import 'package:reins/Constants/constants.dart';
import 'package:reins/Providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'title_divider.dart';

class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Expanded(child: ChatNavigationDrawer()),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 10),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  if (ResponsiveBreakpoints.of(context).isMobile) {
                    Navigator.pop(context);
                  }

                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatNavigationDrawer extends StatelessWidget {
  const ChatNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        return NavigationDrawer(
          selectedIndex: chatProvider.selectedDestination,
          onDestinationSelected: (destination) {
            chatProvider.destinationChatSelected(destination);

            if (ResponsiveBreakpoints.of(context).isMobile) {
              Navigator.pop(context);
            }
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
              child: Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const NavigationDrawerDestination(
              icon: CircleAvatar(
                backgroundImage: AssetImage(AppConstants.ollamaIconPng),
                radius: 16,
              ),
              label: Text("Ollama"),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
              child: TitleDivider(title: "Chats"),
            ),
            ...chatProvider.chats.map((chat) {
              return NavigationDrawerDestination(
                icon: const Icon(Icons.chat_outlined),
                label: Expanded(
                  child: Text(
                    chat.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                selectedIcon: const Icon(Icons.chat),
              );
            }),
          ],
        );
      },
    );
  }
}
