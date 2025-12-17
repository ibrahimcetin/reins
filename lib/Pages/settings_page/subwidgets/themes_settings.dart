import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:reins/Constants/constants.dart';

class ThemesSettings extends StatefulWidget {
  const ThemesSettings({super.key});

  @override
  State<ThemesSettings> createState() => _ThemesSettingsState();
}

class _ThemesSettingsState extends State<ThemesSettings> {
  final _settingsBox = Hive.box('settings');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Themes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: ShapeDecoration(
            shape: StadiumBorder(),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: AssetImage(AppConstants.appIconPng),
                  radius: MediaQuery.of(context).textScaler.scale(16),
                ),
              ),
              Expanded(child: Text("Here is your current theme")),
              IconButton(
                icon: Icon(_brightnessIcon),
                iconSize: MediaQuery.of(context).textScaler.scale(24),
                onPressed: () {
                  setState(() => _toggleBrightness());
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ThemeButton(
              seedColor: Colors.red,
              onPressed: () => _settingsBox.put("color", Colors.red),
            ),
            _ThemeButton(
              seedColor: Colors.green,
              onPressed: () => _settingsBox.put("color", Colors.green),
            ),
            _ThemeButton(
              seedColor: Colors.blue,
              onPressed: () => _settingsBox.put("color", Colors.blue),
            ),
            _ThemeButton(
              seedColor: Colors.purple,
              onPressed: () => _settingsBox.put("color", Colors.purple),
            ),
            _ThemeButton(
              seedColor: Colors.orange,
              onPressed: () => _settingsBox.put("color", Colors.orange),
            ),
            _ThemeButton(
              seedColor: Colors.grey,
              onPressed: () => _settingsBox.put("color", Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleBrightness() {
    final currentBrightness = _settingsBox.get('brightness');
    // Brightness: 1 = light, 0 = dark, null = auto
    // Toggle between light, dark, and auto. 1 > 0 > null > 1 > ...
    final nb = currentBrightness == 1 ? 0 : (currentBrightness == 0 ? null : 1);
    _settingsBox.put('brightness', nb);
  }

  IconData get _brightnessIcon {
    final brightness = _settingsBox.get('brightness');
    if (brightness == null) return Icons.radio_button_off;
    return brightness == 1
        ? Icons.light_mode_outlined
        : Icons.dark_mode_outlined;
  }
}

class _ThemeButton extends StatelessWidget {
  final Color seedColor;
  final Function()? onPressed;

  const _ThemeButton({required this.seedColor, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Theme.of(context).brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainer,
        padding: EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _colorNames[seedColor] ?? "Custom",
            style: TextStyle(color: colorScheme.primary),
          ),
          Container(
            height: 20,
            width: 80,
            decoration: ShapeDecoration(
              color: colorScheme.primary,
              shape: StadiumBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 20,
            width: 80,
            decoration: ShapeDecoration(
              color: colorScheme.surface,
              shape: StadiumBorder(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static final _colorNames = {
    Colors.red: "Red",
    Colors.blue: "Blue",
    Colors.purple: "Purple",
    Colors.orange: "Orange",
    Colors.green: "Green",
    Colors.grey: "Grey",
  };
}
