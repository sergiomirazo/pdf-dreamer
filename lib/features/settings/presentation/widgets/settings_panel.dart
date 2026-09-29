import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
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

    return SingleChildScrollView(
      child: Container(
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
            Text(
              i18n.translate('settings_accent'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const _AccentColorSelector(),
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

class _AccentColorSelector extends StatefulWidget {
  const _AccentColorSelector();

  @override
  State<_AccentColorSelector> createState() => _AccentColorSelectorState();
}

class _AccentColorSelectorState extends State<_AccentColorSelector> {
  static const _colors = <(Color, String)>[
    (AppTheme.accent, 'settings_accent_orange'),
    (Color(0xFF2585C3), 'settings_accent_blue'),
    (Color(0xFF168B70), 'settings_accent_green'),
    (Color(0xFFCC4B91), 'settings_accent_pink'),
    (Color(0xFF7953B5), 'settings_accent_purple'),
  ];

  final TextEditingController _hexController = TextEditingController();
  bool _initialized = false;
  bool _invalidHex = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _hexController.text = _hexOf(
        context.read<SettingsController>().accentColor,
      );
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (color, labelKey) in _colors)
              ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(backgroundColor: color, radius: 9),
                    const SizedBox(width: 7),
                    Text(i18n.translate(labelKey)),
                  ],
                ),
                selected: settings.accentColor == color,
                onSelected: (_) {
                  _hexController.text = _hexOf(color);
                  setState(() => _invalidHex = false);
                  settings.setAccentColor(color);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 150,
              child: TextField(
                controller: _hexController,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: i18n.translate('settings_accent_hex'),
                  prefixText: '#',
                  counterText: '',
                  errorText: _invalidHex
                      ? i18n.translate('settings_accent_invalid')
                      : null,
                ),
                onSubmitted: (_) => _applyHex(settings),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => _applyHex(settings),
              child: Text(i18n.translate('settings_accent_apply')),
            ),
          ],
        ),
      ],
    );
  }

  void _applyHex(SettingsController settings) {
    final value = _hexController.text.trim();
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) {
      setState(() => _invalidHex = true);
      return;
    }
    setState(() => _invalidHex = false);
    settings.setAccentColor(Color(0xFF000000 | int.parse(value, radix: 16)));
  }

  String _hexOf(Color color) => (color.toARGB32() & 0xFFFFFF)
      .toRadixString(16)
      .padLeft(6, '0')
      .toUpperCase();
}
