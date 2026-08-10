import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app/pdf_dreamer_app.dart';
import 'core/platform/file_association_service.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

final settingsController = SettingsController();

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
  }

  if (Platform.isWindows) {
    await FileAssociationService.registerFileAssociations();
  }

  final initialFilePath = args.isNotEmpty ? args.first : null;

  runApp(PdfDreamerApp(
    settingsController: settingsController,
    initialFilePath: initialFilePath,
  ));
}
