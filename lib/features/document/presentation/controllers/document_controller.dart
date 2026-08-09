import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../../data/services/document_export_service.dart';
import '../../data/services/document_picker_service.dart';
import '../../domain/entities/document_edit.dart';
import '../../domain/entities/document_file.dart';
import '../../domain/entities/document_tool.dart';

class DocumentController extends ChangeNotifier {
  DocumentController({
    required DocumentPickerService pickerService,
    required DocumentExportService exportService,
  }) : _pickerService = pickerService,
       _exportService = exportService;

  final DocumentPickerService _pickerService;
  final DocumentExportService _exportService;

  DocumentFile? _document;
  DocumentTool _tool = DocumentTool.select;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isConverting = false;
  bool _isFullscreen = false;
  String? _errorKey;
  String? _successKey;
  bool _hasUnsavedChanges = false;
  double _zoom = 1;
  Color _brushColor = const Color(0xFF7B2CBF);
  double _brushWidth = 4;
  String? _selectedStampId;
  BrushStroke? _draftStroke;
  final List<DocumentEdit> _edits = [];
  final List<DocumentEdit> _redoStack = [];

  DocumentFile? get document => _document;
  DocumentTool get tool => _tool;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isConverting => _isConverting;
  bool get isFullscreen => _isFullscreen;
  String? get errorKey => _errorKey;
  String? get successKey => _successKey;
  double get zoom => _zoom;
  Color get brushColor => _brushColor;
  double get brushWidth => _brushWidth;
  String? get selectedStampId => _selectedStampId;
  BrushStroke? get draftStroke => _draftStroke;
  List<DocumentEdit> get edits => List.unmodifiable(_edits);
  bool get canUndo => _edits.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get hasDocument => _document != null;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get canSave => hasDocument && hasUnsavedChanges && !_isSaving;
  bool get canConvert => hasDocument && !_isConverting;

  Future<void> openDocument() async {
    _setLoading(true);
    try {
      final picked = await _pickerService.pickDocument();
      if (picked == null) {
        return;
      }
      _document = picked;
      _errorKey = null;
      _successKey = null;
      _selectedStampId = null;
      _edits.clear();
      _redoStack.clear();
      _hasUnsavedChanges = false;
    } on FormatException catch (error) {
      _errorKey = error.message;
    } on FileSystemException {
      _errorKey = 'error_read_file';
    } catch (_) {
      _errorKey = 'error_open_document';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addImageSignature(Size canvasSize) async {
    try {
      final bytes = await _pickerService.pickImageBytes();
      if (bytes == null || bytes.isEmpty) {
        return;
      }

      final stamp = ImageStamp(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        bytes: Uint8List.fromList(bytes),
        rect: _initialStampRect(canvasSize),
      );
      _pushEdit(DocumentEdit.image(stamp));
      _selectedStampId = stamp.id;
      _tool = DocumentTool.select;
    } catch (_) {
      _errorKey = 'error_load_image';
      notifyListeners();
    }
  }

  Future<void> saveChanges() async {
    final document = _document;
    if (document == null || _edits.isEmpty || _isSaving) {
      return;
    }

    _isSaving = true;
    notifyListeners();
    try {
      final path = await _exportService.saveDreamerChanges(
        document: document,
        edits: edits,
      );
      if (path == null) {
        return;
      }
      _hasUnsavedChanges = false;
      _successKey = 'success_saved';
    } on FileSystemException {
      _errorKey = 'error_save_file';
    } catch (_) {
      _errorKey = 'error_save_changes';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> convertDocument() async {
    final document = _document;
    if (document == null || _isConverting) {
      return;
    }

    _isConverting = true;
    notifyListeners();
    try {
      final path = document.isMarkdown
          ? await _exportService.convertMarkdownToPdf(document)
          : await _exportService.convertPdfToMarkdown(document);
      if (path == null) {
        return;
      }
      _successKey = document.isMarkdown ? 'success_md_to_pdf' : 'success_pdf_to_md';
    } on FileSystemException {
      _errorKey = 'error_convert_file';
    } catch (_) {
      _errorKey = 'error_convert';
    } finally {
      _isConverting = false;
      notifyListeners();
    }
  }

  void selectTool(DocumentTool tool) {
    _tool = tool;
    if (tool != DocumentTool.select) {
      _selectedStampId = null;
    }
    notifyListeners();
  }

  void setBrushColor(Color color) {
    _brushColor = color;
    notifyListeners();
  }

  void setBrushWidth(double width) {
    _brushWidth = width.clamp(1, 16);
    notifyListeners();
  }

  void startStroke(Offset point) {
    if (_tool != DocumentTool.brush) {
      return;
    }
    _draftStroke = BrushStroke(
      points: [point],
      color: _brushColor,
      width: _brushWidth,
    );
    notifyListeners();
  }

  void appendStroke(Offset point) {
    final draft = _draftStroke;
    if (draft == null) {
      return;
    }
    _draftStroke = draft.copyWith(points: [...draft.points, point]);
    notifyListeners();
  }

  void endStroke() {
    final draft = _draftStroke;
    _draftStroke = null;
    if (draft == null || draft.points.length < 2) {
      notifyListeners();
      return;
    }
    _pushEdit(DocumentEdit.brush(draft));
  }

  void selectStamp(String id) {
    _selectedStampId = id;
    _tool = DocumentTool.select;
    notifyListeners();
  }

  void moveStamp(String id, Offset delta, Size bounds) {
    _replaceStamp(id, (stamp) {
      final moved = stamp.rect.shift(delta);
      return stamp.copyWith(rect: _fitRectInBounds(moved, bounds));
    });
  }

  void resizeStamp(String id, Offset delta, Size bounds) {
    _replaceStamp(id, (stamp) {
      final nextWidth = (stamp.rect.width + delta.dx).clamp(48, bounds.width);
      final nextHeight = (stamp.rect.height + delta.dy).clamp(
        32,
        bounds.height,
      );
      final resized = Rect.fromLTWH(
        stamp.rect.left,
        stamp.rect.top,
        nextWidth.toDouble(),
        nextHeight.toDouble(),
      );
      return stamp.copyWith(rect: _fitRectInBounds(resized, bounds));
    });
  }

  void fixSelectedStamp() {
    final id = _selectedStampId;
    if (id == null) {
      return;
    }
    _replaceStamp(id, (stamp) => stamp.copyWith(fixed: true));
    _selectedStampId = null;
    notifyListeners();
  }

  void deleteSelectedStamp() {
    final id = _selectedStampId;
    if (id == null) {
      return;
    }
    final index = _edits.indexWhere((edit) => edit.stamp?.id == id);
    if (index < 0) {
      return;
    }
    _edits.removeAt(index);
    _redoStack.clear();
    _hasUnsavedChanges = true;
    _selectedStampId = null;
    notifyListeners();
  }

  void undo() {
    if (_edits.isEmpty) {
      return;
    }
    _redoStack.add(_edits.removeLast());
    _selectedStampId = null;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    _edits.add(_redoStack.removeLast());
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void zoomIn() {
    _zoom = (_zoom + 0.1).clamp(0.5, 3);
    notifyListeners();
  }

  void zoomOut() {
    _zoom = (_zoom - 0.1).clamp(0.5, 3);
    notifyListeners();
  }

  void setZoom(double value) {
    _zoom = value.clamp(0.5, 3);
    notifyListeners();
  }

  Future<void> toggleFullscreen() async {
    _isFullscreen = !_isFullscreen;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setFullScreen(_isFullscreen);
    } else {
      final mode = _isFullscreen
          ? SystemUiMode.immersiveSticky
          : SystemUiMode.edgeToEdge;
      await SystemChrome.setEnabledSystemUIMode(mode);
    }
    notifyListeners();
  }

  void clearError() {
    _errorKey = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successKey = null;
    notifyListeners();
  }

  Rect _initialStampRect(Size canvasSize) {
    final width = (canvasSize.width * 0.28).clamp(140, 280).toDouble();
    final height = width * 0.45;
    return Rect.fromCenter(
      center: Offset(canvasSize.width / 2, canvasSize.height / 2),
      width: width,
      height: height,
    );
  }

  Rect _fitRectInBounds(Rect rect, Size bounds) {
    final maxLeft = (bounds.width - rect.width).clamp(0, bounds.width);
    final maxTop = (bounds.height - rect.height).clamp(0, bounds.height);
    return Rect.fromLTWH(
      rect.left.clamp(0, maxLeft).toDouble(),
      rect.top.clamp(0, maxTop).toDouble(),
      rect.width.clamp(48, bounds.width).toDouble(),
      rect.height.clamp(32, bounds.height).toDouble(),
    );
  }

  void _pushEdit(DocumentEdit edit) {
    _edits.add(edit);
    _redoStack.clear();
    _errorKey = null;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void _replaceStamp(String id, ImageStamp Function(ImageStamp stamp) map) {
    final index = _edits.indexWhere((edit) => edit.stamp?.id == id);
    if (index < 0) {
      return;
    }
    final stamp = _edits[index].stamp;
    if (stamp == null) {
      return;
    }
    _edits[index] = DocumentEdit.image(map(stamp));
    _redoStack.clear();
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
