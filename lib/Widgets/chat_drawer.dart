import 'package:flutter/material.dart';
import 'package:ollama_chat/Pages/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';

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
                  Navigator.pop(context);

                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const SettingsPage();
                  }));
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

            Navigator.pop(context);
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
              child: Text(
                'Ollama Chat',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const NavigationDrawerDestination(
              icon: CircleAvatar(
                backgroundImage: AssetImage("assets/images/ollama.png"),
                radius: 16,
              ),
              label: Text("Ollama"),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Chats'),
                  ),
                  Expanded(child: Divider())
                ],
              ),
            ),
            ...chatProvider.chats.map((chat) {
              return NavigationDrawerDestination(
                icon: const Icon(Icons.chat_outlined),
                label: Text(chat.title),
                selectedIcon: const Icon(Icons.chat),
              );
            }),
          ],
        );
      },
    );
  }
}
