import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../domain/entities/document_file.dart';

class DocumentPickerService {
  const DocumentPickerService();

  DocumentFile? resolveFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File does not exist or is not a file', path);
    }
    final name = path.split(Platform.pathSeparator).last;
    final extension = _extensionOf(name);
    if (extension == 'pdf') {
      // Verify access without loading the whole PDF into memory.
      file.openSync().closeSync();
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
    if (_imageExtensions.contains(extension)) {
      return DocumentFile(
        path: path,
        name: name,
        kind: DocumentKind.image,
        bytes: file.readAsBytesSync(),
      );
    }
    return null;
  }

  Future<DocumentFile?> pickDocument() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'md', 'markdown', 'png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );

    final picked = result?.files.single;
    if (picked == null) {
      return null;
    }

    final extension = _extensionOf(picked.name);
    if (extension == 'pdf') {
      return DocumentFile(
        path: picked.path ?? '',
        name: picked.name,
        kind: DocumentKind.pdf,
      );
    }

    if (extension == 'md' || extension == 'markdown') {
      final content = await _readText(picked);
      return DocumentFile(
        path: picked.path ?? '',
        name: picked.name,
        kind: DocumentKind.markdown,
        markdownContent: content,
      );
    }

    if (_imageExtensions.contains(extension)) {
      final bytes = await _readBytes(picked);
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return DocumentFile(
        path: picked.path ?? '',
        name: picked.name,
        kind: DocumentKind.image,
        bytes: bytes,
      );
    }

    throw const FormatException(
      'Formato no compatible. Usa PDF, MD, Markdown o una imagen (PNG, JPG, JPEG, WEBP).',
    );
  }

  Future<String?> pickPdfPath() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    final picked = result?.files.single;
    final path = picked?.path;
    if (path == null || path.trim().isEmpty) {
      return null;
    }
    return path;
  }

  Future<List<String>> pickPdfPaths() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return const [];
    }
    return [
      for (final file in result.files)
        if (file.path != null && file.path!.trim().isNotEmpty) file.path!,
    ];
  }

  Future<String?> pickDirectory() async {
    final directory = await FilePicker.getDirectoryPath();
    if (directory == null || directory.trim().isEmpty) {
      return null;
    }
    return directory;
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

  static const List<String> _imageExtensions = ['png', 'jpg', 'jpeg', 'webp'];

  Future<String> _readText(PlatformFile file) async {
    if (file.path != null && file.path!.trim().isNotEmpty) {
      return File(file.path!).readAsString();
    }
    return String.fromCharCodes(file.bytes ?? const []);
  }

  Future<Uint8List?> _readBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes;
    }
    if (file.path != null && file.path!.trim().isNotEmpty) {
      return File(file.path!).readAsBytes();
    }
    return null;
  }

  String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) {
      return '';
    }
    return name.substring(dot + 1).toLowerCase();
  }
}
