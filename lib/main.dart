import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yty_claim_app/src/controllers/claim_controller.dart';
import 'package:yty_claim_app/src/controllers/claim_service.dart';

import 'package:yty_claim_app/src/app.dart';
import 'package:yty_claim_app/src/controllers/settings_controller.dart';
import 'package:yty_claim_app/src/controllers/settings_service.dart';
import 'package:yty_claim_app/src/controllers/update_controller.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SettingsController settingsController =
      SettingsController(SettingsService());
  final ClaimController claimController = ClaimController(ClaimService());

  await settingsController.loadSettings();
  await claimController.loadClaims();
  await claimController.loadClaimTypes();
  await claimController.loadCurrencies();

  if (await UpdateController.getUpdateStatus(MyApp.appVersion)) {
    await (UpdateController.tryOtaUpdate());
  }

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
