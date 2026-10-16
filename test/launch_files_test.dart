import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_dreamer/features/document/data/services/document_export_service.dart';
import 'package:pdf_dreamer/features/document/data/services/document_picker_service.dart';
import 'package:pdf_dreamer/features/document/data/services/document_tools_service.dart';
import 'package:pdf_dreamer/features/document/presentation/controllers/document_controller.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('dreamer ágil '));
  tearDown(() => directory.deleteSync(recursive: true));

  DocumentController controller(List<String> args) => DocumentController(
    pickerService: const DocumentPickerService(),
    exportService: const DocumentExportService(),
    toolsService: const DocumentToolsService(),
    initialFilePaths: args,
  );

  test(
    'preserves spaces, Unicode, uppercase extension and Markdown content',
    () {
      final file = File('${directory.path}/lectura ágil 日本語.MD')
        ..writeAsStringSync('# Hola ágil');
      final subject = controller([file.path]);
      addTearDown(subject.dispose);
      expect(subject.document, isNull);
      subject.openInitialDocuments();
      expect(subject.document?.path, file.path);
      expect(subject.document?.markdownContent, '# Hola ágil');
      expect(subject.errorKey, isNull);
    },
  );

  test('opens only first argument and reports remaining files', () {
    final first = File('${directory.path}/first.md')
      ..writeAsStringSync('first');
    final second = File('${directory.path}/second.md')
      ..writeAsStringSync('second');
    final subject = controller([first.path, second.path]);
    addTearDown(subject.dispose);
    subject.openInitialDocuments();
    expect(subject.document?.path, first.path);
    expect(subject.errorKey, 'notice_first_file_only');
    subject.clearError();
    subject.openInitialDocuments();
    expect(subject.errorKey, isNull); // Initial request is consumed once.
  });

  test('missing paths and directories report read errors without throwing', () {
    for (final path in ['${directory.path}/missing.pdf', directory.path]) {
      final subject = controller([path]);
      addTearDown(subject.dispose);
      subject.openInitialDocuments();
      expect(subject.document, isNull);
      expect(subject.errorKey, 'error_read_file');
      expect(subject.isLoading, isFalse);
    }
  });

  test('unsupported files and malformed UTF-8 do not crash startup', () {
    final unsupported = File('${directory.path}/file.exe')
      ..writeAsStringSync('');
    final malformed = File('${directory.path}/bad.md')
      ..writeAsBytesSync([0xff]);
    for (final file in [unsupported, malformed]) {
      final subject = controller([file.path]);
      addTearDown(subject.dispose);
      subject.openInitialDocuments();
      expect(subject.document, isNull);
      expect(
        subject.errorKey,
        file == unsupported ? 'error_unsupported_file' : 'error_read_file',
      );
      expect(subject.isLoading, isFalse);
    }
  });

  test('uppercase PDF path resolves as PDF', () {
    final file = File('${directory.path}/lectura ágil.PDF')
      ..writeAsStringSync('%PDF-1.7');
    final document = const DocumentPickerService().resolveFile(file.path);
    expect(document?.isPdf, isTrue);
  });
}
