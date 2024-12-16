import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reins/Constants/constants.dart';
import 'package:reins/Widgets/chat_configure_bottom_sheet.dart';
import 'package:reins/Widgets/ollama_bottom_sheet_header.dart';
import 'package:reins/Widgets/selection_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:reins/Providers/chat_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return AppBar(
      title: Column(
        children: [
          Text(AppConstants.appName, style: GoogleFonts.pacifico()),
          if (chatProvider.currentChat != null)
            InkWell(
              onTap: () {
                _handleModelSelectionButton(context);
              },
              customBorder: StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  chatProvider.currentChat!.model,
                  style: GoogleFonts.kodeMono(
                    textStyle: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () {
            _handleConfigureButton(context);
          },
        ),
      ],
      forceMaterialTransparency: !ResponsiveBreakpoints.of(context).isMobile,
    );
  }

  Future<void> _handleModelSelectionButton(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final selectedModelName = await showSelectionBottomSheet(
      key: ValueKey("${Hive.box('settings').get('serverAddress')}-string"),
      context: context,
      header: OllamaBottomSheetHeader(title: "Change The Model"),
      fetchItems: () async {
        final models = await chatProvider.fetchAvailableModels();

        return models.map((model) => model.name).toList();
      },
      currentSelection: chatProvider.currentChat!.model,
    );

    await chatProvider.updateCurrentChat(newModel: selectedModelName);
  }

  Future<void> _handleConfigureButton(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final arguments = chatProvider.currentChatConfiguration;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: ChatConfigureBottomSheet(arguments: arguments),
        );
      },
    );

    await chatProvider.updateCurrentChat(
      newSystemPrompt: arguments.systemPrompt,
      newOptions: arguments.chatOptions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
