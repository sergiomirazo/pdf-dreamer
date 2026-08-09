import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../controllers/settings_controller.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            i18n.translate('settings_title'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Text(
            i18n.translate('settings_language'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const _LanguageSelector(),
          const SizedBox(height: 24),
          Text(
            i18n.translate('settings_theme'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const _ThemeSelector(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(i18n.translate('settings_close')),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final currentLocale = settings.locale;

    return SegmentedButton<Locale>(
      segments: const [
        ButtonSegment(value: Locale('es'), label: Text('Español')),
        ButtonSegment(value: Locale('pt'), label: Text('Português')),
        ButtonSegment(value: Locale('en'), label: Text('English')),
      ],
      selected: {currentLocale},
      onSelectionChanged: (selected) {
        settings.setLocale(selected.first);
      },
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();
    final currentTheme = settings.themeMode;

    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text(i18n.translate('settings_theme_system')),
          icon: const Icon(Icons.brightness_auto),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text(i18n.translate('settings_theme_light')),
          icon: const Icon(Icons.light_mode),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text(i18n.translate('settings_theme_dark')),
          icon: const Icon(Icons.dark_mode),
        ),
      ],
      selected: {currentTheme},
      onSelectionChanged: (selected) {
        settings.setThemeMode(selected.first);
      },
    );
  }
}
