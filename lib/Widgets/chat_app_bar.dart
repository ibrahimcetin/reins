import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ollama_chat/Widgets/chat_configure_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const ChatAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return AppBar(
      forceMaterialTransparency: !ResponsiveBreakpoints.of(context).isMobile,
      title: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.pacifico(), // kodeMono,
          ),
          if (chatProvider.currentChat != null)
            Text(
              chatProvider.currentChat!.model,
              style: GoogleFonts.kodeMono(
                textStyle: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return const ChatConfigureBottomSheet();
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
