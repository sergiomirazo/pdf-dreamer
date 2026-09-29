import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/document_edit.dart';
import '../../domain/entities/document_file.dart';
import '../../domain/entities/document_tool.dart';
import '../controllers/document_controller.dart';

class DocumentCanvas extends StatefulWidget {
  const DocumentCanvas({super.key});

  @override
  State<DocumentCanvas> createState() => _DocumentCanvasState();
}

class _DocumentCanvasState extends State<DocumentCanvas> {
  final PdfViewerController _pdfController = PdfViewerController();
  double _lastAppliedPdfZoom = 1;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _syncPdfZoom(controller.zoom);
        final document = controller.document;

        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: document == null
                ? const _EmptyDocumentState()
                : document.isMarkdown
                ? _MarkdownWorkspace(
                    key: ValueKey(document.path),
                    document: document,
                    controller: controller,
                    viewportSize: size,
                  )
                : document.isImage
                ? _ImageDocumentRenderer(
                    key: ValueKey(document.path),
                    document: document,
                    controller: controller,
                    viewportSize: size,
                  )
                : Stack(
                    key: ValueKey(document.path),
                    children: [
                      Positioned.fill(
                        child: _PdfDocumentRenderer(
                          document: document,
                          pdfController: _pdfController,
                          zoom: controller.zoom,
                          controller: controller,
                        ),
                      ),
                      Positioned.fill(
                        child: _DocumentEditLayer(
                          canvasSize: size,
                          controller: controller,
                        ),
                      ),
                      if (controller.tool == DocumentTool.imageSignature)
                        Positioned.fill(
                          child: _ImageUploadTarget(
                            onTap: () => controller.addImageSignature(size),
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _syncPdfZoom(double zoom) {
    if (!_pdfController.isReady || _lastAppliedPdfZoom == zoom) {
      return;
    }
    _lastAppliedPdfZoom = zoom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pdfController.isReady) {
        return;
      }
      _pdfController.setZoom(
        _pdfController.centerPosition,
        zoom,
        duration: const Duration(milliseconds: 120),
      );
    });
  }
}

class _MarkdownWorkspace extends StatefulWidget {
  const _MarkdownWorkspace({
    super.key,
    required this.document,
    required this.controller,
    required this.viewportSize,
  });

  final DocumentFile document;
  final DocumentController controller;
  final Size viewportSize;

  @override
  State<_MarkdownWorkspace> createState() => _MarkdownWorkspaceState();
}

class _MarkdownWorkspaceState extends State<_MarkdownWorkspace> {
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoom = widget.controller.zoom;
    final availableWidth = widget.viewportSize.width - 56;
    final pageWidth = (860 * zoom).clamp(0, availableWidth).toDouble();
    final pageMinHeight = 900 * zoom;

    return Stack(
      children: [
        Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            primary: false,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
            child: Center(
              child: Stack(
                children: [
                  _MarkdownPage(
                    document: widget.document,
                    width: pageWidth,
                    minHeight: pageMinHeight,
                    zoom: zoom,
                  ),
                  Positioned.fill(
                    child: _DocumentEditLayer(
                      canvasSize: Size(
                        pageWidth,
                        pageMinHeight > widget.viewportSize.height
                            ? pageMinHeight
                            : widget.viewportSize.height,
                      ),
                      controller: widget.controller,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.controller.tool == DocumentTool.imageSignature)
          Positioned.fill(
            child: _ImageUploadTarget(
              onTap: () => widget.controller.addImageSignature(
                Size(pageWidth, pageMinHeight),
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageDocumentRenderer extends StatelessWidget {
  const _ImageDocumentRenderer({
    super.key,
    required this.document,
    required this.controller,
    required this.viewportSize,
  });

  final DocumentFile document;
  final DocumentController controller;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    final bytes = document.bytes;
    if (bytes == null || bytes.isEmpty) {
      return const _DocumentErrorState();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Center(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: _DocumentEditLayer(
            canvasSize: viewportSize,
            controller: controller,
          ),
        ),
        if (controller.tool == DocumentTool.imageSignature)
          Positioned.fill(
            child: _ImageUploadTarget(
              onTap: () => controller.addImageSignature(viewportSize),
            ),
          ),
      ],
    );
  }
}

class _PdfDocumentRenderer extends StatelessWidget {
  const _PdfDocumentRenderer({
    required this.document,
    required this.pdfController,
    required this.zoom,
    required this.controller,
  });

  final DocumentFile document;
  final PdfViewerController pdfController;
  final double zoom;
  final DocumentController controller;

  @override
  Widget build(BuildContext context) {
    return PdfViewer.file(
      document.path,
      controller: pdfController,
      params: PdfViewerParams(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        minScale: 0.5,
        maxScale: 3,
        useAlternativeFitScaleAsMinScale: false,
        margin: 18,
        pageDropShadow: const BoxShadow(
          color: Color(0x22000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
        textSelectionParams: PdfTextSelectionParams(
          enabled: controller.pdfSelectionEnabled,
          showContextMenuAutomatically:
              controller.showSelectionMenuAutomatically,
          onTextSelectionChange: controller.setPdfTextSelection,
        ),
        buildContextMenu: _buildTextSelectionContextMenu,
        loadingBannerBuilder: (context, _, __) {
          return const Center(child: CircularProgressIndicator());
        },
        errorBannerBuilder: (context, error, stackTrace, documentRef) {
          return const _DocumentErrorState();
        },
        onViewerReady: (_, viewerController) {
          viewerController.setZoom(
            viewerController.centerPosition,
            zoom,
            duration: Duration.zero,
          );
        },
      ),
    );
  }

  static Widget? _buildTextSelectionContextMenu(
    BuildContext context,
    PdfViewerContextMenuBuilderParams params,
  ) {
    final i18n = AppLocalizations.of(context);
    final items = <ContextMenuButtonItem>[
      if (params.isTextSelectionEnabled &&
          params.textSelectionDelegate.isCopyAllowed &&
          params.textSelectionDelegate.hasSelectedText)
        ContextMenuButtonItem(
          onPressed: () => params.textSelectionDelegate.copyTextSelection(),
          label: i18n.translate('context_copy'),
          type: ContextMenuButtonType.copy,
        ),
      if (params.isTextSelectionEnabled &&
          !params.textSelectionDelegate.isSelectingAllText)
        ContextMenuButtonItem(
          onPressed: () => params.textSelectionDelegate.selectAllText(),
          label: i18n.translate('context_select_all'),
          type: ContextMenuButtonType.selectAll,
        ),
    ];

    if (items.isEmpty) {
      return null;
    }

    return Align(
      alignment: Alignment.topLeft,
      child: AdaptiveTextSelectionToolbar.buttonItems(
        anchors: TextSelectionToolbarAnchors(
          primaryAnchor: params.anchorA,
          secondaryAnchor: params.anchorB,
        ),
        buttonItems: items,
      ),
    );
  }
}

class _MarkdownPage extends StatelessWidget {
  const _MarkdownPage({
    required this.document,
    required this.width,
    required this.minHeight,
    required this.zoom,
  });

  final DocumentFile document;
  final double width;
  final double minHeight;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final content = document.markdownContent ?? '';

    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.fromLTRB(56 * zoom, 48 * zoom, 56 * zoom, 72 * zoom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: MarkdownBody(
        selectable: true,
        data: content,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16 * zoom,
            height: 1.55,
          ),
          h1: TextStyle(
            color: AppTheme.primary,
            fontSize: 30 * zoom,
            fontWeight: FontWeight.w800,
          ),
          h2: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24 * zoom,
            fontWeight: FontWeight.w800,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentEditLayer extends StatelessWidget {
  const _DocumentEditLayer({
    required this.canvasSize,
    required this.controller,
  });

  final Size canvasSize;
  final DocumentController controller;

  @override
  Widget build(BuildContext context) {
    final layer = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _StrokePainter(
                edits: controller.edits,
                draftStroke: controller.draftStroke,
                draftHighlight: controller.draftHighlight,
              ),
            ),
          ),
        ),
        for (final stamp in _stampsFrom(controller.edits))
          _StampOverlay(
            key: ValueKey(stamp.id),
            stamp: stamp,
            isSelected: controller.selectedStampId == stamp.id,
            onSelect: () => controller.selectStamp(stamp.id),
            onMove: (delta) =>
                controller.moveStamp(stamp.id, delta, canvasSize),
            onResize: (delta) =>
                controller.resizeStamp(stamp.id, delta, canvasSize),
          ),
      ],
    );

    if (controller.tool != DocumentTool.brush &&
        controller.tool != DocumentTool.highlight) {
      return layer;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) => controller.startStroke(details.localPosition),
      onPanUpdate: (details) => controller.appendStroke(details.localPosition),
      onPanEnd: (_) => controller.endStroke(),
      child: layer,
    );
  }

  static List<ImageStamp> _stampsFrom(List<DocumentEdit> edits) {
    return [
      for (final edit in edits)
        if (edit.stamp != null) edit.stamp!,
    ];
  }
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter({
    required this.edits,
    required this.draftStroke,
    required this.draftHighlight,
  });

  final List<DocumentEdit> edits;
  final BrushStroke? draftStroke;
  final HighlightStroke? draftHighlight;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edit in edits) {
      final stroke = edit.stroke;
      if (stroke != null) {
        _paintStroke(canvas, stroke);
        continue;
      }
      final highlight = edit.highlight;
      if (highlight != null) {
        _paintHighlight(canvas, highlight);
      }
    }
    final draft = draftStroke;
    if (draft != null) {
      _paintStroke(canvas, draft);
    }
    final draftMark = draftHighlight;
    if (draftMark != null) {
      _paintHighlight(canvas, draftMark);
    }
  }

  void _paintStroke(Canvas canvas, BrushStroke stroke) {
    if (stroke.points.length < 2) {
      return;
    }
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (final point in stroke.points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintHighlight(Canvas canvas, HighlightStroke highlight) {
    if (highlight.points.length < 2) {
      return;
    }
    final paint = Paint()
      ..color = AppTheme.highlightInk
      ..strokeWidth = highlight.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.multiply
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(highlight.points.first.dx, highlight.points.first.dy);
    for (final point in highlight.points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) {
    return oldDelegate.edits != edits ||
        oldDelegate.draftStroke != draftStroke ||
        oldDelegate.draftHighlight != draftHighlight;
  }
}

class _StampOverlay extends StatelessWidget {
  const _StampOverlay({
    super.key,
    required this.stamp,
    required this.isSelected,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
  });

  final ImageStamp stamp;
  final bool isSelected;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onResize;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return Positioned.fromRect(
      rect: stamp.rect,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: stamp.fixed
            ? i18n.translate('stamp_fixed')
            : i18n.translate('stamp_editable'),
        child: GestureDetector(
          onTap: onSelect,
          onPanStart: (_) => onSelect(),
          onPanUpdate: stamp.fixed ? null : (details) => onMove(details.delta),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: stamp.opacity,
                  child: Image.memory(stamp.bytes, fit: BoxFit.contain),
                ),
                if (isSelected && !stamp.fixed)
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) => onResize(details.delta),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageUploadTarget extends StatelessWidget {
  const _ImageUploadTarget({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return Material(
      color: AppTheme.primary.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    i18n.translate('canvas_upload_prompt'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDocumentState extends StatelessWidget {
  const _EmptyDocumentState();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DocumentController>();
    final i18n = AppLocalizations.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppTheme.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              i18n.translate('canvas_empty_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              i18n.translate('canvas_empty_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedInk,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: controller.openDocument,
              icon: const Icon(Icons.folder_open_rounded),
              label: Text(i18n.translate('canvas_open_button')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentErrorState extends StatelessWidget {
  const _DocumentErrorState();

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 10),
            Text(
              i18n.translate('canvas_pdf_error'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              i18n.translate('canvas_pdf_error_detail'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedInk),
            ),
          ],
        ),
      ),
    );
  }
}
