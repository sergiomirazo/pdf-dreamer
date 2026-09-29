import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart' as rx;

import '../../domain/entities/document_file.dart';
import 'image_bytes_utils.dart';

class DocumentToolsService {
  const DocumentToolsService();

  Future<int> getPdfPageCount(String path) async {
    final document = await rx.PdfDocument.openFile(path);
    try {
      return document.pages.length;
    } finally {
      await document.dispose();
    }
  }

  Future<String?> applyWatermark({
    required DocumentFile document,
    required Uint8List watermarkBytes,
  }) async {
    final watermark = await ImageBytesUtils.decode(watermarkBytes);
    try {
      if (document.isPdf) {
        return _applyWatermarkToPdf(document, watermark);
      }
      if (document.isImage) {
        return _applyWatermarkToImage(document, watermark);
      }
      throw const FormatException('Documento no compatible para marca de agua.');
    } finally {
      watermark.dispose();
    }
  }

  Future<int> splitPdf({
    required String pdfPath,
    required String outputDirectory,
  }) async {
    final source = await rx.PdfDocument.openFile(pdfPath);
    try {
      final baseName = p.basenameWithoutExtension(pdfPath);
      var index = 1;
      for (final page in source.pages) {
        final pagePng = await _renderPagePng(page);
        final pdf = pw.Document();
        pdf.addPage(_pageFromPng(page.width, page.height, pagePng));
        final name = '${baseName}_pagina_$index.pdf';
        await File(p.join(outputDirectory, name)).writeAsBytes(await pdf.save());
        index++;
      }
      return index - 1;
    } finally {
      await source.dispose();
    }
  }

  Future<String?> mergePdfs({required List<String> pdfPaths}) async {
    final pdf = pw.Document();
    for (final path in pdfPaths) {
      final source = await rx.PdfDocument.openFile(path);
      try {
        for (final page in source.pages) {
          final pagePng = await _renderPagePng(page);
          pdf.addPage(_pageFromPng(page.width, page.height, pagePng));
        }
      } finally {
        await source.dispose();
      }
    }
    return _savePdf(
      pdf: pdf,
      fileName: 'documentos_unidos.pdf',
      dialogTitle: 'Unir PDFs',
    );
  }

  Future<String?> deletePdfPages({
    required DocumentFile document,
    required Set<int> pagesToDelete,
  }) async {
    final source = await rx.PdfDocument.openFile(document.path);
    try {
      final pdf = pw.Document();
      for (final page in source.pages) {
        if (pagesToDelete.contains(page.pageNumber)) {
          continue;
        }
        final pagePng = await _renderPagePng(page);
        pdf.addPage(_pageFromPng(page.width, page.height, pagePng));
      }
      return _savePdf(
        pdf: pdf,
        fileName: '${p.basenameWithoutExtension(document.name)}_editado.pdf',
        dialogTitle: 'Eliminar paginas',
      );
    } finally {
      await source.dispose();
    }
  }

  Future<String?> _applyWatermarkToPdf(
    DocumentFile document,
    ui.Image watermark,
  ) async {
    final source = await rx.PdfDocument.openFile(document.path);
    try {
      final pdf = pw.Document();
      for (final page in source.pages) {
        final pagePng = await _renderPagePng(page);
        final composed = await _composeWatermark(pagePng, watermark);
        pdf.addPage(_pageFromPng(page.width, page.height, composed));
      }
      return _savePdf(
        pdf: pdf,
        fileName: '${p.basenameWithoutExtension(document.name)}_watermark.pdf',
        dialogTitle: 'Aplicar marca de agua',
      );
    } finally {
      await source.dispose();
    }
  }

  Future<String?> _applyWatermarkToImage(
    DocumentFile document,
    ui.Image watermark,
  ) async {
    final bytes = document.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('La imagen no contiene datos.');
    }
    final png = await ImageBytesUtils.encodePng(bytes);
    final composed = await _composeWatermark(png, watermark);
    final image = await ImageBytesUtils.decode(composed);
    final size = ui.Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();

    final pdf = pw.Document();
    final pageFormat = size.width >= size.height
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;
    final contentArea = ui.Size(
      pageFormat.width - pageFormat.marginLeft - pageFormat.marginRight,
      pageFormat.height - pageFormat.marginTop - pageFormat.marginBottom,
    );
    final fitted = _fitInside(size, contentArea);
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (_) => pw.Center(
          child: pw.Image(
            pw.MemoryImage(composed),
            width: fitted.width,
            height: fitted.height,
            fit: pw.BoxFit.fill,
          ),
        ),
      ),
    );

    return _savePdf(
      pdf: pdf,
      fileName: '${p.basenameWithoutExtension(document.name)}_watermark.pdf',
      dialogTitle: 'Aplicar marca de agua',
    );
  }

  pw.Page _pageFromPng(double widthPt, double heightPt, Uint8List png) {
    return pw.Page(
      pageFormat: PdfPageFormat(widthPt, heightPt),
      build: (_) => pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.fill),
    );
  }

  Future<Uint8List> _renderPagePng(rx.PdfPage page, {double scale = 2}) async {
    final rendered = await page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
      backgroundColor: 0xFFFFFFFF,
    );
    if (rendered == null) {
      throw const FormatException('No se pudo renderizar la pagina.');
    }
    try {
      final image = await rendered.createImage();
      try {
        return await ImageBytesUtils.imageToPng(image);
      } finally {
        image.dispose();
      }
    } finally {
      rendered.dispose();
    }
  }

  Future<Uint8List> _composeWatermark(
    Uint8List pagePng,
    ui.Image watermark,
  ) async {
    final pageImage = await ImageBytesUtils.decode(pagePng);
    try {
      final width = pageImage.width;
      final height = pageImage.height;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImage(pageImage, ui.Offset.zero, ui.Paint());

      final maxWidth = width * 0.45;
      final maxHeight = height * 0.45;
      final scale = math.min(
        maxWidth / watermark.width,
        maxHeight / watermark.height,
      );
      final w = watermark.width * scale;
      final h = watermark.height * scale;
      final target = ui.Rect.fromLTWH(
        (width - w) / 2,
        (height - h) / 2,
        w,
        h,
      );

      final paint = ui.Paint()
        ..colorFilter = const ui.ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 0.25, 0,
        ]);
      canvas.drawImageRect(
        watermark,
        ui.Rect.fromLTWH(
          0,
          0,
          watermark.width.toDouble(),
          watermark.height.toDouble(),
        ),
        target,
        paint,
      );

      final picture = recorder.endRecording();
      final composed = await picture.toImage(width, height);
      try {
        return await ImageBytesUtils.imageToPng(composed);
      } finally {
        composed.dispose();
      }
    } finally {
      pageImage.dispose();
    }
  }

  ui.Size _fitInside(ui.Size source, ui.Size target) {
    final scale = math.min(
      target.width / source.width,
      target.height / source.height,
    );
    return ui.Size(source.width * scale, source.height * scale);
  }

  Future<String?> _savePdf({
    required pw.Document pdf,
    required String fileName,
    required String dialogTitle,
  }) async {
    final bytes = await pdf.save();
    final path = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );
    if (path == null) {
      return null;
    }
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
