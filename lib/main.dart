import 'package:flutter/material.dart';
import 'package:ollama_chat/Pages/main_page.dart';
import 'package:ollama_chat/Pages/settings_page/settings_page.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:ollama_chat/Utils/material_color_adapter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(MaterialColorAdapter());

  await Hive.openBox('settings');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: const OllamaChatApp(),
    ),
  );
}

class OllamaChatApp extends StatelessWidget {
  const OllamaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(keys: ['color']),
      builder: (context, box, _) {
        return MaterialApp(
          title: 'Ollama Chat',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: box.get('color', defaultValue: Colors.grey),
              brightness:
                  View.of(context).platformDispatcher.platformBrightness,
              dynamicSchemeVariant: DynamicSchemeVariant.neutral,
            ),
            appBarTheme: const AppBarTheme(centerTitle: true),
            useMaterial3: true,
          ),
          routes: {
            '/': (context) => const OllamaChatMainPage(title: 'Ollama Chat'),
            '/settings': (context) => const SettingsPage(),
          },
        );
      },
    );
  }
}
