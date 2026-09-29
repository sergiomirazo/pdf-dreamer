import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_dreamer/app/pdf_dreamer_app.dart';
import 'package:pdf_dreamer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:pdf_dreamer/features/settings/presentation/widgets/settings_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('accent color changes the theme and is saved', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController();
    await tester.pumpWidget(PdfDreamerApp(settingsController: settings));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPanel), findsOneWidget);

    await tester.tap(find.text('Azul'));
    await tester.pumpAndSettle();
    const blue = Color(0xFF2585C3);
    expect(settings.accentColor, blue);
    expect(
      Theme.of(
        tester.element(find.byType(SettingsPanel)),
      ).colorScheme.secondary,
      blue,
    );

    await tester.enterText(find.byType(TextField), '12AB34');
    await tester.ensureVisible(find.text('Aplicar'));
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    const custom = Color(0xFF12AB34);
    expect(settings.accentColor, custom);
    expect(
      Theme.of(
        tester.element(find.byType(SettingsPanel)),
      ).colorScheme.secondary,
      custom,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('app_accent_color'), custom.toARGB32());
  });
}
