import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../domain/entities/document_file.dart';

class DocumentPickerService {
  const DocumentPickerService();

  DocumentFile? resolveFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    final name = path.split(Platform.pathSeparator).last;
    final extension = _extensionOf(name);
    if (extension == 'pdf') {
      return DocumentFile(
        path: path,
        name: name,
        kind: DocumentKind.pdf,
      );
    }
    if (extension == 'md' || extension == 'markdown') {
      final content = file.readAsStringSync();
      return DocumentFile(
        path: path,
        name: name,
        kind: DocumentKind.markdown,
        markdownContent: content,
      );
    }
    return null;
  }

  Future<DocumentFile?> pickDocument() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'md', 'markdown'],
      withData: false,
    );

    final picked = result?.files.single;
    final path = picked?.path;
    if (picked == null || path == null || path.trim().isEmpty) {
      return null;
    }

    final extension = _extensionOf(picked.name);
    if (extension == 'pdf') {
      return DocumentFile(
        path: path,
        name: picked.name,
        kind: DocumentKind.pdf,
      );
    }

    if (extension == 'md' || extension == 'markdown') {
      final file = File(path);
      final content = await file.readAsString();
      return DocumentFile(
        path: path,
        name: picked.name,
        kind: DocumentKind.markdown,
        markdownContent: content,
      );
    }

    throw const FormatException(
      'Formato no compatible. Usa PDF, MD o Markdown.',
    );
  }

  Future<List<int>?> pickImageBytes() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );

    final file = result?.files.single;
    final bytes = file?.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return bytes;
    }

    final path = file?.path;
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    return File(path).readAsBytes();
  }

  String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) {
      return '';
    }
    return name.substring(dot + 1).toLowerCase();
  }
}
