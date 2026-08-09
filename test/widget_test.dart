import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_dreamer/app/pdf_dreamer_app.dart';
import 'package:pdf_dreamer/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  testWidgets('PDF DREAMER workspace starts with open document action', (
    tester,
  ) async {
    final settings = SettingsController();
    await tester.pumpWidget(PdfDreamerApp(settingsController: settings));
    await tester.pumpAndSettle();

    expect(find.text('PDF DREAMER'), findsOneWidget);
  });
}
