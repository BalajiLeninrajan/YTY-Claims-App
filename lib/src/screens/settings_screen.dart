import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/app.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';
import 'package:yty_claim_app/src/controllers/update_controller.dart';
import 'package:yty_claim_app/src/screens/login_screen.dart';
import 'package:yty_claim_app/src/controllers/settings_controller.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.claimController,
  });

  static const routeName = '/settings';

  final SettingsController controller;
  final ClaimController claimController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Stack(
        children: [
          Center(
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
                    value: widget.controller.themeMode,
                    // Call the updateThemeMode method any time the user selects a theme.
                    onChanged: widget.controller.updateThemeMode,
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
                      widget.controller.logout();
                      widget.claimController.clearClaims();
                      widget.claimController.clearClaimTypes();
                      widget.claimController.clearCurrencies();
                      Navigator.popAndPushNamed(
                        context,
                        LoginScreen.routeName,
                      );
                    },
                    label: const Text('Logout'),
                    icon: const Icon(Icons.logout),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      bool status = await UpdateController.getUpdateStatus(
                          MyApp.appVersion);
                      if (status) {
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Attempting Update'),
                            ),
                          );
                        }

                        setState(() => _isLoading = false);
                      } else {
                        setState(() => _isLoading = false);
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Already at latest version'),
                            ),
                          );
                        }
                      }
                    },
                    label: const Text('Update'),
                    icon: const Icon(Icons.download),
                  ),
                  const SizedBox(height: 16),
                  const Text('Version: ${MyApp.appVersion}'),
                  const SizedBox(height: 128),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Theme.of(context).dialogBackgroundColor.withOpacity(0.5),
              child: const Center(
                child: RefreshProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
