import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_dreamer/features/document/data/services/markdown_pdf_renderer.dart';
import 'package:pdf_dreamer/features/document/domain/entities/document_file.dart';

void main() {
  const markdown = '''# Informe de prueba

Texto con **negritas**, *cursivas* y una liga [OpenAI](https://openai.com).

| Tema | Valor |
| --- | --- |
| Español | áéíóú ñ |

```dart
final total = 42;
```

> Una cita con formato.
''';

  final document = DocumentFile(
    path: 'test/fixtures/sample.md',
    name: 'sample.md',
    kind: DocumentKind.markdown,
    markdownContent: markdown,
  );

  test('creates HTML with rich Markdown elements', () {
    final html = const MarkdownPdfRenderer().buildHtml(document);
    expect(html, contains('<strong>negritas</strong>'));
    expect(html, contains('<table>'));
    expect(html, contains('<pre><code class="language-dart">'));
    expect(html, contains('Español'));
  });

  test('creates a PDF and removes its HTML working directory', () async {
    final browser = MarkdownPdfRenderer.findBrowserExecutable();
    if (browser == null) return;

    final temporaryRoot = await Directory.systemTemp.createTemp(
      'pdf_dreamer_test_',
    );
    try {
      final bytes = await MarkdownPdfRenderer(
        browserExecutable: browser,
        temporaryDirectory: temporaryRoot,
      ).render(document);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(await temporaryRoot.list().toList(), isEmpty);
    } finally {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('removes the HTML working directory when rendering fails', () async {
    final temporaryRoot = await Directory.systemTemp.createTemp(
      'pdf_dreamer_test_',
    );
    try {
      await expectLater(
        MarkdownPdfRenderer(
          browserExecutable: '${temporaryRoot.path}/missing-browser.exe',
          temporaryDirectory: temporaryRoot,
        ).render(document),
        throwsA(isA<ProcessException>()),
      );
      expect(await temporaryRoot.list().toList(), isEmpty);
    } finally {
      await temporaryRoot.delete(recursive: true);
    }
  });
}
