import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app/pdf_dreamer_app.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

final settingsController = SettingsController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
  }
  runApp(PdfDreamerApp(settingsController: settingsController));
}
