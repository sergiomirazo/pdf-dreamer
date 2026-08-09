import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../features/document/data/services/document_export_service.dart';
import '../features/document/data/services/document_picker_service.dart';
import '../features/document/presentation/controllers/document_controller.dart';
import '../features/document/presentation/pages/document_workspace_page.dart';
import '../features/settings/presentation/controllers/settings_controller.dart';

class PdfDreamerApp extends StatelessWidget {
  const PdfDreamerApp({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsController),
        ChangeNotifierProvider(
          create: (_) => DocumentController(
            pickerService: const DocumentPickerService(),
            exportService: const DocumentExportService(),
          ),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'PDF DREAMER',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
              Locale('pt'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const DocumentWorkspacePage(),
          );
        },
      ),
    );
  }
}
