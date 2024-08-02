import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/app.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';
import 'package:yty_claim_app/src/screens/login_screen.dart';

import '../controllers/settings_controller.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.claimController,
  });

  static const routeName = '/settings';

  final SettingsController controller;
  final ClaimController claimController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          // Glue the SettingsController to the theme selection DropdownButton.
          //
          // When a user selects a theme from the dropdown list, the
          // SettingsController is updated, which rebuilds the MaterialApp.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<ThemeMode>(
                // Read the selected themeMode from the controller
                value: controller.themeMode,
                // Call the updateThemeMode method any time the user selects a theme.
                onChanged: controller.updateThemeMode,
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System Theme'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light Theme'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark Theme'),
                  )
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  controller.logout();
                  claimController.clearClaims();
                  claimController.clearClaimTypes();
                  claimController.clearCurrencies();
                  Navigator.popAndPushNamed(
                    context,
                    LoginScreen.routeName,
                  );
                },
                label: const Text('Logout'),
                icon: const Icon(Icons.logout),
              ),
              const SizedBox(height: 32),
              const Text('Version: ${MyApp.appVersion}'),
              const SizedBox(height: 128),
            ],
          ),
        ),
      ),
    );
  }
}
