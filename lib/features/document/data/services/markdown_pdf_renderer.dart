import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;

import '../../domain/entities/document_file.dart';

/// Renders Markdown with a browser so PDF layout follows the HTML document.
class MarkdownPdfRenderer {
  const MarkdownPdfRenderer({this.browserExecutable, this.temporaryDirectory});

  final String? browserExecutable;
  final Directory? temporaryDirectory;

  Future<Uint8List> render(DocumentFile document) async {
    final browser = browserExecutable ?? findBrowserExecutable();
    if (browser == null) {
      throw UnsupportedError(
        'No Chromium-based browser is available for PDF export.',
      );
    }

    final workDirectory = await (temporaryDirectory ?? Directory.systemTemp)
        .createTemp('pdf_dreamer_md_');
    try {
      final htmlFile = File(p.join(workDirectory.path, 'document.html'));
      final pdfFile = File(p.join(workDirectory.path, 'document.pdf'));
      await htmlFile.writeAsString(buildHtml(document), encoding: utf8);

      final process = await Process.start(browser, [
        '--headless',
        '--disable-gpu',
        '--disable-extensions',
        '--no-first-run',
        '--no-default-browser-check',
        '--no-pdf-header-footer',
        '--allow-file-access-from-files',
        '--user-data-dir=${p.join(workDirectory.path, 'browser-profile')}',
        '--print-to-pdf=${pdfFile.path}',
        htmlFile.uri.toString(),
      ]);

      final stdoutText = process.stdout
          .transform(systemEncoding.decoder)
          .join();
      final stderrText = process.stderr
          .transform(systemEncoding.decoder)
          .join();
      int exitCode;
      try {
        exitCode = await process.exitCode.timeout(const Duration(seconds: 60));
      } on TimeoutException {
        process.kill();
        await process.exitCode;
        throw const FileSystemException(
          'Timed out while rendering Markdown PDF.',
        );
      }
      await stdoutText;
      final browserError = await stderrText;
      if (exitCode != 0 || !await pdfFile.exists()) {
        throw FileSystemException(
          'Browser PDF rendering failed (exit $exitCode): $browserError',
        );
      }

      final bytes = await pdfFile.readAsBytes();
      if (bytes.length < 5 || ascii.decode(bytes.sublist(0, 5)) != '%PDF-') {
        throw const FormatException('Browser did not create a valid PDF.');
      }
      return bytes;
    } finally {
      await workDirectory.delete(recursive: true);
    }
  }

  String buildHtml(DocumentFile document) {
    final body = md.markdownToHtml(
      document.markdownContent ?? '',
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
    final title = const HtmlEscape(
      HtmlEscapeMode.element,
    ).convert(document.name);
    final base = const HtmlEscape(
      HtmlEscapeMode.attribute,
    ).convert(File(document.path).absolute.parent.uri.toString());
    return '''<!doctype html>
<html lang="und">
<head>
  <meta charset="utf-8">
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src 'self' file: data: https:; style-src 'unsafe-inline'">
  <base href="$base">
  <title>$title</title>
  <style>
    @page { size: A4; margin: 18mm 16mm; }
    html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    body { color: #201a2e; font: 11pt/1.5 "Segoe UI", Arial, sans-serif; overflow-wrap: anywhere; }
    h1, h2, h3, h4 { color: #7b2cbf; line-height: 1.25; break-after: avoid; }
    h1 { font-size: 22pt; margin: 0 0 14pt; }
    h2 { font-size: 17pt; margin: 16pt 0 8pt; }
    h3 { font-size: 13pt; margin: 13pt 0 6pt; }
    p, ul, ol, blockquote, pre, table { margin: 0 0 10pt; }
    li { margin-bottom: 3pt; }
    blockquote { border-left: 3pt solid #ff914d; padding: 4pt 0 4pt 12pt; color: #514a5e; }
    code { font-family: Consolas, "Courier New", monospace; font-size: 9pt; }
    pre { padding: 10pt; border-radius: 4pt; background: #f3f0f8; white-space: pre-wrap; overflow-wrap: anywhere; }
    table { width: 100%; border-collapse: collapse; }
    th, td { border: 1px solid #d9d2e3; padding: 6pt 8pt; text-align: left; vertical-align: top; overflow-wrap: break-word; }
    th { background: #f3f0f8; }
    tr, img { break-inside: avoid; }
    img { max-width: 100%; height: auto; }
    a { color: #5d2a9a; text-decoration: underline; }
  </style>
</head>
<body>
$body
</body>
</html>''';
  }

  static String? findBrowserExecutable() {
    final environment = Platform.environment;
    String? env(String name) {
      for (final entry in environment.entries) {
        if (entry.key.toUpperCase() == name) return entry.value;
      }
      return null;
    }

    final candidates = <String>[];
    if (Platform.isWindows) {
      for (final root in [
        env('LOCALAPPDATA'),
        env('PROGRAMFILES'),
        env('PROGRAMFILES(X86)'),
      ]) {
        if (root == null || root.isEmpty) continue;
        candidates.addAll([
          p.join(root, 'Microsoft', 'Edge', 'Application', 'msedge.exe'),
          p.join(root, 'Google', 'Chrome', 'Application', 'chrome.exe'),
        ]);
      }
    } else if (Platform.isMacOS) {
      candidates.addAll([
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
      ]);
    }

    final path = env('PATH') ?? '';
    final names = Platform.isWindows
        ? ['msedge.exe', 'chrome.exe', 'chromium.exe']
        : ['chromium', 'chromium-browser', 'google-chrome', 'microsoft-edge'];
    for (final directory in path.split(Platform.isWindows ? ';' : ':')) {
      if (directory.isEmpty) continue;
      for (final name in names) {
        candidates.add(p.join(directory, name));
      }
    }
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }
}
