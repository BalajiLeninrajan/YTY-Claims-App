import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';
import 'package:yty_claim_app/src/screens/add_claim_screen.dart';

import 'package:yty_claim_app/src/screens/home_screen.dart';
import 'package:yty_claim_app/src/screens/login_screen.dart';
import 'package:yty_claim_app/src/controllers/settings_controller.dart';
import 'package:yty_claim_app/src/screens/settings_screen.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
    required this.claimController,
  });

  final SettingsController settingsController;
  final ClaimController claimController;

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return DynamicColorBuilder(
          builder:
              (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
            return MaterialApp(
              // Providing a restorationScopeId allows the Navigator built by the
              // MaterialApp to restore the navigation stack when a user leaves and
              // returns to the app after it has been killed while running in the
              // background.
              restorationScopeId: 'app',

              // Provide the generated AppLocalizations to the MaterialApp. This
              // allows descendant Widgets to display the correct translations
              // depending on the user's locale.
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', ''), // English, no country code
              ],

              // Use AppLocalizations to configure the correct application title
              // depending on the user's locale.
              //
              // The appTitle is defined in .arb files found in the localization
              // directory.
              onGenerateTitle: (BuildContext context) =>
                  AppLocalizations.of(context)!.appTitle,

              // Define a light and dark color theme. Then, read the user's
              // preferred ThemeMode (light, dark, or system default) from the
              // SettingsController to display the correct theme.
              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: darkColorScheme ?? const ColorScheme.dark(),
                useMaterial3: true,
              ),
              themeMode: settingsController.themeMode,

              // Define a function to handle named routes in order to support
              // Flutter web url navigation and deep linking.
              onGenerateRoute: (RouteSettings routeSettings) {
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (BuildContext context) {
                    if (settingsController.loginFlag.isEmpty) {
                      return LoginScreen(controller: settingsController);
                    }
                    switch (routeSettings.name) {
                      case SettingsScreen.routeName:
                        return SettingsScreen(controller: settingsController);
                      case AddClaimScreen.routeName:
                        return AddClaimScreen(controller: claimController);
                      case LoginScreen.routeName:
                        return LoginScreen(controller: settingsController);
                      case HomeScreen.routeName:
                      default:
                        return HomeScreen(
                          claimController: claimController,
                          settingsController: settingsController,
                        );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
