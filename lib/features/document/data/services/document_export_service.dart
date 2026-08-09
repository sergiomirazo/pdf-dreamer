import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart' as rx;

import '../../domain/entities/document_edit.dart';
import '../../domain/entities/document_file.dart';

class DocumentExportService {
  const DocumentExportService();

  Future<String?> saveDreamerChanges({
    required DocumentFile document,
    required List<DocumentEdit> edits,
  }) async {
    final payload = const JsonEncoder.withIndent('  ').convert({
      'format': 'pdf_dreamer_changes',
      'version': 1,
      'document': {
        'path': document.path,
        'name': document.name,
        'kind': document.kind.name,
      },
      'savedAt': DateTime.now().toIso8601String(),
      'edits': edits.map(_editToJson).toList(),
    });

    final path = await FilePicker.saveFile(
      dialogTitle: 'Guardar cambios PDF DREAMER',
      fileName: '${p.basenameWithoutExtension(document.name)}.pdfdreamer.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: Uint8List.fromList(utf8.encode(payload)),
    );
    if (path == null) {
      return null;
    }
    await File(path).writeAsString(payload);
    return path;
  }

  Future<String?> convertMarkdownToPdf(DocumentFile document) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(42),
          pageFormat: PdfPageFormat.a4,
        ),
        build: (context) => [
          pw.Text(
            p.basenameWithoutExtension(document.name),
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#7b2cbf'),
            ),
          ),
          pw.SizedBox(height: 18),
          ..._markdownToPdfWidgets(document.markdownContent ?? ''),
        ],
      ),
    );

    return _saveBytes(
      bytes: await pdf.save(),
      dialogTitle: 'Convertir Markdown a PDF',
      fileName: '${p.basenameWithoutExtension(document.name)}.pdf',
      extensions: const ['pdf'],
    );
  }

  Future<String?> convertPdfToMarkdown(DocumentFile document) async {
    final pdf = await rx.PdfDocument.openFile(document.path);
    try {
      final buffer = StringBuffer()
        ..writeln('# ${p.basenameWithoutExtension(document.name)}')
        ..writeln();

      for (final page in pdf.pages) {
        final text = (await page.loadText()).trim();
        if (text.isEmpty) {
          continue;
        }
        buffer
          ..writeln('## Pagina ${page.pageNumber}')
          ..writeln()
          ..writeln(_normalizePdfText(text))
          ..writeln();
      }

      final markdown = buffer.toString();
      final path = await FilePicker.saveFile(
        dialogTitle: 'Convertir PDF a Markdown',
        fileName: '${p.basenameWithoutExtension(document.name)}.md',
        type: FileType.custom,
        allowedExtensions: const ['md'],
        bytes: Uint8List.fromList(utf8.encode(markdown)),
      );
      if (path == null) {
        return null;
      }
      await File(path).writeAsString(markdown);
      return path;
    } finally {
      await pdf.dispose();
    }
  }

  Future<String?> _saveBytes({
    required Uint8List bytes,
    required String dialogTitle,
    required String fileName,
    required List<String> extensions,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: extensions,
      bytes: bytes,
    );
    if (path == null) {
      return null;
    }
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Iterable<pw.Widget> _markdownToPdfWidgets(String markdown) sync* {
    final lines = const LineSplitter().convert(markdown);
    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        yield pw.SizedBox(height: 8);
        continue;
      }
      if (line.startsWith('# ')) {
        yield pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
          child: pw.Text(
            line.substring(2).trim(),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#7b2cbf'),
            ),
          ),
        );
        continue;
      }
      if (line.startsWith('## ')) {
        yield pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
          child: pw.Text(
            line.substring(3).trim(),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        );
        continue;
      }
      if (line.startsWith('- ') || line.startsWith('* ')) {
        yield pw.Bullet(text: line.substring(2).trim());
        continue;
      }
      yield pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
      );
    }
  }

  String _normalizePdfText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Map<String, Object?> _editToJson(DocumentEdit edit) {
    final stroke = edit.stroke;
    if (stroke != null) {
      return {
        'type': 'brushStroke',
        'color': stroke.color.toARGB32(),
        'width': stroke.width,
        'fixed': stroke.fixed,
        'points': [
          for (final point in stroke.points) {'x': point.dx, 'y': point.dy},
        ],
      };
    }

    final stamp = edit.stamp!;
    return {
      'type': 'imageStamp',
      'id': stamp.id,
      'fixed': stamp.fixed,
      'opacity': stamp.opacity,
      'rect': {
        'left': stamp.rect.left,
        'top': stamp.rect.top,
        'width': stamp.rect.width,
        'height': stamp.rect.height,
      },
      'imageBase64': base64Encode(stamp.bytes),
    };
  }
}
