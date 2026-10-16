import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/document_tool.dart';
import '../controllers/document_controller.dart';
import '../widgets/document_canvas.dart';
import '../widgets/document_tool_rail.dart';
import '../widgets/workspace_top_bar.dart';

class DocumentWorkspacePage extends StatefulWidget {
  const DocumentWorkspacePage({super.key});

  @override
  State<DocumentWorkspacePage> createState() => _DocumentWorkspacePageState();
}

class _DocumentWorkspacePageState extends State<DocumentWorkspacePage> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'document-workspace');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DocumentController>().openInitialDocuments();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentController>(
      builder: (context, controller, _) {
        final i18n = AppLocalizations.of(context);
        final errorKey = controller.errorKey;
        if (errorKey != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(i18n.translate(errorKey)),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: i18n.translate('snackbar_close'),
                  onPressed: controller.clearError,
                ),
              ),
            );
            controller.clearError();
          });
        }
        final successKey = controller.successKey;
        if (successKey != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(i18n.translate(successKey)),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            controller.clearSuccess();
          });
        }

        return Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            const SingleActivator(LogicalKeyboardKey.f5):
                const _ToggleFullscreenIntent(),
            const SingleActivator(
              LogicalKeyboardKey.keyF,
              meta: true,
              control: true,
            ): const _ToggleFullscreenIntent(),
            const SingleActivator(LogicalKeyboardKey.keyO, control: true):
                const _OpenDocumentIntent(),
            const SingleActivator(LogicalKeyboardKey.keyS, control: true):
                const _SaveChangesIntent(),
            const SingleActivator(
              LogicalKeyboardKey.keyC,
              control: true,
              shift: true,
            ): const _ConvertDocumentIntent(),
            const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
                const _UndoIntent(),
            const SingleActivator(
              LogicalKeyboardKey.keyZ,
              control: true,
              shift: true,
            ): const _RedoIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _ToggleFullscreenIntent: CallbackAction<_ToggleFullscreenIntent>(
                onInvoke: (_) => controller.toggleFullscreen(),
              ),
              _OpenDocumentIntent: CallbackAction<_OpenDocumentIntent>(
                onInvoke: (_) => controller.openDocument(),
              ),
              _SaveChangesIntent: CallbackAction<_SaveChangesIntent>(
                onInvoke: (_) => controller.saveChanges(),
              ),
              _ConvertDocumentIntent: CallbackAction<_ConvertDocumentIntent>(
                onInvoke: (_) => controller.convertDocument(),
              ),
              _UndoIntent: CallbackAction<_UndoIntent>(
                onInvoke: (_) => controller.undo(),
              ),
              _RedoIntent: CallbackAction<_RedoIntent>(
                onInvoke: (_) => controller.redo(),
              ),
            },
            child: Focus(
              focusNode: _focusNode,
              autofocus: true,
              child: Scaffold(
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      return Column(
                        children: [
                          const WorkspaceTopBar(),
                          Expanded(
                            child: isNarrow ? _NarrowLayout() : _WideLayout(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WideLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        DocumentToolRail(),
        Expanded(child: DocumentCanvas()),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        DocumentCompactToolBar(),
        Expanded(child: DocumentCanvas()),
      ],
    );
  }
}

class DocumentCompactToolBar extends StatelessWidget {
  const DocumentCompactToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final brushColors = [
      Color(0xFF7B2CBF),
      Theme.of(context).colorScheme.secondary,
      Color(0xFF111827),
      Color(0xFF00A896),
      Color(0xFFE63946),
    ];

    return Consumer<DocumentController>(
      builder: (context, controller, _) {
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IconButton(
                  tooltip: i18n.translate('tool_select'),
                  isSelected: controller.tool == DocumentTool.select,
                  onPressed: () => controller.selectTool(DocumentTool.select),
                  icon: const Icon(Icons.near_me_rounded),
                ),
                IconButton(
                  tooltip: i18n.translate('tool_brush'),
                  isSelected: controller.tool == DocumentTool.brush,
                  onPressed: () => controller.selectTool(DocumentTool.brush),
                  icon: const Icon(Icons.draw_rounded),
                ),
                IconButton(
                  tooltip: i18n.translate('tool_highlight'),
                  isSelected: controller.tool == DocumentTool.highlight,
                  onPressed: controller.hasDocument
                      ? () => controller.selectTool(DocumentTool.highlight)
                      : null,
                  icon: const Icon(Icons.border_color_rounded),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<Color>(
                  tooltip: i18n.translate('tool_brush_color'),
                  icon: Icon(
                    Icons.palette_rounded,
                    color: controller.brushColor,
                    size: 22,
                  ),
                  onSelected: controller.setBrushColor,
                  itemBuilder: (_) => [
                    for (final c in brushColors)
                      PopupMenuItem(
                        value: c,
                        child: _ColorOption(color: c, i18n: i18n),
                      ),
                  ],
                ),
                SizedBox(
                  width: 130,
                  child: Slider(
                    value: controller.brushWidth,
                    min: 1,
                    max: 16,
                    divisions: 15,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: controller.setBrushWidth,
                  ),
                ),
                IconButton(
                  tooltip: i18n.translate('tool_copy_text'),
                  isSelected: controller.tool == DocumentTool.copyText,
                  onPressed:
                      controller.hasDocument && controller.document!.isPdf
                      ? () => controller.selectTool(DocumentTool.copyText)
                      : null,
                  icon: const Icon(Icons.text_fields_rounded),
                ),
                IconButton(
                  tooltip: i18n.translate('tool_copy'),
                  onPressed: controller.canCopyPdfText
                      ? controller.copyPdfText
                      : null,
                  icon: const Icon(Icons.content_copy_rounded),
                ),
                IconButton(
                  tooltip: i18n.translate('tool_image'),
                  onPressed: controller.hasDocument
                      ? () => controller.selectTool(DocumentTool.imageSignature)
                      : null,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                ),
                const VerticalDivider(width: 20),
                IconButton(
                  tooltip: i18n.translate('tool_undo'),
                  onPressed: controller.canUndo ? controller.undo : null,
                  icon: const Icon(Icons.undo_rounded),
                ),
                IconButton(
                  tooltip: i18n.translate('tool_redo'),
                  onPressed: controller.canRedo ? controller.redo : null,
                  icon: const Icon(Icons.redo_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({required this.color, required this.i18n});

  final Color color;
  final AppLocalizations i18n;

  @override
  Widget build(BuildContext context) {
    final key = _colorKey(color, Theme.of(context).colorScheme.secondary);
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 10),
        Text(i18n.translate(key)),
      ],
    );
  }

  static String _colorKey(Color color, Color accent) {
    const primary = Color(0xFF7B2CBF);
    const black = Color(0xFF111827);
    const green = Color(0xFF00A896);
    const red = Color(0xFFE63946);
    if (color == primary) return 'color_primary';
    if (color == accent) return 'color_accent';
    if (color == black) return 'color_black';
    if (color == green) return 'color_green';
    if (color == red) return 'color_red';
    return 'color_default';
  }
}

class _ToggleFullscreenIntent extends Intent {
  const _ToggleFullscreenIntent();
}

class _OpenDocumentIntent extends Intent {
  const _OpenDocumentIntent();
}

class _SaveChangesIntent extends Intent {
  const _SaveChangesIntent();
}

class _ConvertDocumentIntent extends Intent {
  const _ConvertDocumentIntent();
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}
