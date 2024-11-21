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
          Text(title, style: GoogleFonts.pacifico()),
          if (chatProvider.currentChat != null)
            Text(
              chatProvider.currentChat!.model,
              style: GoogleFonts.kodeMono(
                textStyle: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () {
            _handleCustomizeButton(context);
          },
        ),
      ],
      forceMaterialTransparency: !ResponsiveBreakpoints.of(context).isMobile,
    );
  }

  void _handleCustomizeButton(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: const ChatConfigureBottomSheet(),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
