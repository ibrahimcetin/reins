import 'package:flutter/material.dart';
import 'package:ollama_chat/Models/settings_route_arguments.dart';
import 'package:ollama_chat/Pages/main_page.dart';
import 'package:ollama_chat/Pages/settings_page/settings_page.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:ollama_chat/Utils/material_color_adapter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
          builder: (context, child) => ResponsiveBreakpoints.builder(
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            ],
            child: child!,
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              return MaterialPageRoute(
                builder: (context) =>
                    const OllamaChatMainPage(title: 'Ollama Chat'),
              );
            }

            if (settings.name == '/settings') {
              final args = settings.arguments as SettingsRouteArguments?;

              return MaterialPageRoute(
                builder: (context) => SettingsPage(arguments: args),
              );
            }

            assert(false, 'Need to implement ${settings.name}');
            return null;
          },
        );
      },
    );
  }
}
