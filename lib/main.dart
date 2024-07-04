import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';
import 'package:yty_claim_app/src/controllers/claim_service.dart';

import 'src/app.dart';
import 'src/controllers/settings_controller.dart';
import 'src/controllers/settings_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  final settingsController = SettingsController(SettingsService());
  final claimController = ClaimController(ClaimService());

  await settingsController.loadSettings();
  await claimController.loadClaims();

  // http overide
  // TODO: REMOVE FOR PROD
  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MyApp(
      settingsController: settingsController,
      claimController: claimController,
    ),
  );
}
