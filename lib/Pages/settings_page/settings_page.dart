import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'subwidgets/subwidgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.pacifico()),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ThemesSettings(),
              SizedBox(height: 16),
              ServerSettings(),
            ],
          ),
        ),
      ),
    );
  }
}
