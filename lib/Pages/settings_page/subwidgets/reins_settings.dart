import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:in_app_review/in_app_review.dart';
import 'dart:io' show Platform;

import 'package:reins/Widgets/flexible_text.dart';

class ReinsSettings extends StatelessWidget {
  const ReinsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reins',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        ListTile(
          leading: Icon(Icons.rate_review),
          title: Text('Review Reins'),
          subtitle: Text('Share your feedback'),
          onTap: () async {
            if (await InAppReview.instance.isAvailable() && Platform.isIOS) {
              InAppReview.instance.openStoreListing(appStoreId: "6739738501");
            } else {
              launchUrlString('https://github.com/ibrahimcetin/reins');
            }
          },
        ),
        ListTile(
          leading: Icon(Icons.share),
          title: Text('Share Reins'),
          subtitle: Text('Share Reins with your friends'),
          onTap: () {
            Share.share(
              'Check out Reins: https://github.com/ibrahimcetin/reins',
            );
          },
        ),
        if (Platform.isAndroid || Platform.isIOS)
          ListTile(
            leading: Icon(Icons.desktop_mac_outlined),
            title: Text('Try Desktop App'),
            subtitle: Text('Available on macOS and Linux'),
            onTap: () {
              launchUrlString('https://reins.ibrahimcetin.dev');
            },
          ),
        if (Platform.isMacOS || Platform.isLinux || Platform.isWindows)
          ListTile(
            leading: Icon(Icons.phone_iphone_outlined),
            title: Text('Try Mobile App'),
            subtitle: Text('Available on iOS'),
            onTap: () {
              launchUrlString('https://reins.ibrahimcetin.dev');
            },
          ),
        ListTile(
          leading: Icon(Icons.code),
          title: Text('Go to Source Code'),
          subtitle: Text('View on GitHub'),
          onTap: () {
            launchUrlString('https://github.com/ibrahimcetin/reins');
          },
        ),
        ListTile(
          leading: Icon(Icons.star),
          title: Text('Give a Star on GitHub'),
          subtitle: Text('Support the project'),
          onTap: () {
            launchUrlString('https://github.com/ibrahimcetin/reins');
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 16),
            FlexibleText(
              "Thanks for using Reins!",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}
