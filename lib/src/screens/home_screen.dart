import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/YTY.png',
          height: 32,
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.send),
          ),
          IconButton(
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsScreen.routeName);
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: const Placeholder(),
    );
  }
}
