import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart' as rx;

import '../../domain/entities/document_edit.dart';
import '../../domain/entities/document_file.dart';
import 'image_bytes_utils.dart';
import 'markdown_pdf_renderer.dart';

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
    final bytes = Platform.isAndroid || Platform.isIOS
        ? await _renderMarkdownOnMobile(document)
        : await const MarkdownPdfRenderer().render(document);
    return _saveBytes(
      bytes: bytes,
      dialogTitle: 'Convertir Markdown a PDF',
      fileName: '${p.basenameWithoutExtension(document.name)}.pdf',
      extensions: const ['pdf'],
    );
  }

  Future<String?> convertImageToPdf(DocumentFile document) async {
    final bytes = document.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const FileSystemException('La imagen no contiene datos.');
    }

    final pngBytes = await ImageBytesUtils.encodePng(bytes);
    final image = await ImageBytesUtils.decode(pngBytes);
    final imageSize = ui.Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();

    final pageFormat = _imagePageFormat(imageSize);
    final fitted = _fitInside(imageSize, _imageContentArea(pageFormat));

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (_) => pw.Center(
          child: pw.Image(
            pw.MemoryImage(pngBytes),
            width: fitted.width,
            height: fitted.height,
            fit: pw.BoxFit.fill,
          ),
        ),
      ),
    );

    return _saveBytes(
      bytes: await pdf.save(),
      dialogTitle: 'Convertir imagen a PDF',
      fileName: '${p.basenameWithoutExtension(document.name)}.pdf',
      extensions: const ['pdf'],
    );
  }

  PdfPageFormat _imagePageFormat(ui.Size imageSize) {
    final landscape = imageSize.width >= imageSize.height;
    if (landscape) {
      return PdfPageFormat.a4.landscape;
    }
    return PdfPageFormat.a4;
  }

  ui.Size _imageContentArea(PdfPageFormat format) {
    return ui.Size(
      format.width - format.marginLeft - format.marginRight,
      format.height - format.marginTop - format.marginBottom,
    );
  }

  ui.Size _fitInside(ui.Size source, ui.Size target) {
    final scale = math.min(
      target.width / source.width,
      target.height / source.height,
    );
    return ui.Size(source.width * scale, source.height * scale);
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

  // Mobile platforms do not expose a desktop browser executable. Keep their
  // existing PDF path until a native HTML print renderer is available.
  Future<Uint8List> _renderMarkdownOnMobile(DocumentFile document) async {
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
    return pdf.save();
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

    final highlight = edit.highlight;
    if (highlight != null) {
      return {
        'type': 'highlight',
        'width': highlight.width,
        'fixed': highlight.fixed,
        'points': [
          for (final point in highlight.points) {'x': point.dx, 'y': point.dy},
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
