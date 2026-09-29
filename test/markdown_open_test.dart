import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_dreamer/app/pdf_dreamer_app.dart';
import 'package:pdf_dreamer/features/document/presentation/controllers/document_controller.dart';
import 'package:pdf_dreamer/features/document/presentation/widgets/document_canvas.dart';
import 'package:pdf_dreamer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('opens a Markdown file in the workspace', (tester) async {
    final settings = SettingsController();
    await tester.pumpWidget(
      PdfDreamerApp(settingsController: settings, initialFilePath: 'README.md'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DocumentCanvas), findsOneWidget);
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(
      tester
          .element(find.byType(DocumentCanvas))
          .read<DocumentController>()
          .document
          ?.isMarkdown,
      isTrue,
    );
  });
}
