import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/settings/presentation/widgets/settings_panel.dart';
import '../controllers/document_controller.dart';

class WorkspaceTopBar extends StatelessWidget {
  const WorkspaceTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentController>();
    final i18n = AppLocalizations.of(context);
    final document = controller.document;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Container(
          height: isCompact ? 52 : 68,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 16),
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
                Image.asset(
                  'assets/img/PDF-DREAMER-LOGO.png',
                  width: isCompact ? 28 : 36,
                  height: isCompact ? 28 : 36,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.auto_stories_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: isCompact ? 24 : 32,
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  Text(
                    i18n.translate('app_title'),
                    semanticsLabel: 'PDF Dreamer',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                SizedBox(
                  width: isCompact ? 120 : 190,
                  child: Text(
                    document?.name ?? i18n.translate('topbar_no_document'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.mutedInk,
                      fontWeight: FontWeight.w600,
                      fontSize: isCompact ? 12 : 14,
                    ),
                  ),
                ),
                _ZoomButton(
                  icon: Icons.remove_rounded,
                  tooltip: i18n.translate('topbar_zoom_out'),
                  onPressed: controller.zoomOut,
                  compact: isCompact,
                ),
                SizedBox(
                  width: isCompact ? 72 : 104,
                  child: Slider(
                    value: controller.zoom,
                    min: 0.5,
                    max: 3,
                    divisions: isCompact ? 10 : 25,
                    activeColor: AppTheme.primary,
                    secondaryActiveColor: Theme.of(
                      context,
                    ).colorScheme.secondary,
                    label: '${(controller.zoom * 100).round()}%',
                    onChanged: controller.setZoom,
                  ),
                ),
                Text(
                  '${(controller.zoom * 100).round()}%',
                  style: TextStyle(
                    color: AppTheme.mutedInk,
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 11 : 14,
                  ),
                ),
                _ZoomButton(
                  icon: Icons.add_rounded,
                  tooltip: i18n.translate('topbar_zoom_in'),
                  onPressed: controller.zoomIn,
                  compact: isCompact,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: controller.isFullscreen
                        ? i18n.translate('topbar_fullscreen_exit')
                        : i18n.translate('topbar_fullscreen_enter'),
                    onPressed: controller.toggleFullscreen,
                    icon: Icon(
                      controller.isFullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: controller.canSave ? controller.saveChanges : null,
                  icon: controller.isSaving
                      ? SizedBox.square(
                          dimension: isCompact ? 14 : 18,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.save_rounded, size: isCompact ? 16 : 20),
                  label: Text(
                    i18n.translate('topbar_save'),
                    style: TextStyle(fontSize: isCompact ? 12 : 14),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: controller.canConvert
                      ? controller.convertDocument
                      : null,
                  icon: controller.isConverting
                      ? SizedBox.square(
                          dimension: isCompact ? 14 : 18,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.sync_alt_rounded, size: isCompact ? 16 : 20),
                  label: Text(
                    document?.isMarkdown == true || document?.isImage == true
                        ? i18n.translate('topbar_to_pdf')
                        : i18n.translate('topbar_to_md'),
                    style: TextStyle(fontSize: isCompact ? 12 : 14),
                  ),
                ),
                const SizedBox(width: 6),
                PopupMenuButton<_PdfToolsAction>(
                  tooltip: i18n.translate('tools_menu'),
                  iconSize: isCompact ? 20 : 24,
                  icon: controller.isProcessing
                      ? SizedBox.square(
                          dimension: isCompact ? 16 : 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.handyman_rounded),
                  onSelected: (action) {
                    switch (action) {
                      case _PdfToolsAction.watermark:
                        controller.addWatermark();
                      case _PdfToolsAction.split:
                        controller.splitPdf();
                      case _PdfToolsAction.merge:
                        controller.mergePdfs();
                      case _PdfToolsAction.deletePages:
                        _openDeletePagesDialog(context, controller);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _PdfToolsAction.watermark,
                      enabled:
                          controller.canAddWatermark &&
                          !controller.isProcessing,
                      child: _ToolsMenuItem(
                        icon: Icons.branding_watermark_rounded,
                        label: i18n.translate('tools_watermark'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _PdfToolsAction.split,
                      enabled: !controller.isProcessing,
                      child: _ToolsMenuItem(
                        icon: Icons.call_split_rounded,
                        label: i18n.translate('tools_split'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _PdfToolsAction.merge,
                      enabled: !controller.isProcessing,
                      child: _ToolsMenuItem(
                        icon: Icons.merge_rounded,
                        label: i18n.translate('tools_merge'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _PdfToolsAction.deletePages,
                      enabled:
                          controller.canDeletePages && !controller.isProcessing,
                      child: _ToolsMenuItem(
                        icon: Icons.delete_sweep_rounded,
                        label: i18n.translate('tools_delete_pages'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: controller.isLoading
                      ? null
                      : controller.openDocument,
                  icon: controller.isLoading
                      ? SizedBox.square(
                          dimension: isCompact ? 14 : 18,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.folder_open_rounded,
                          size: isCompact ? 16 : 20,
                        ),
                  label: Text(
                    i18n.translate('topbar_open'),
                    style: TextStyle(fontSize: isCompact ? 12 : 14),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: i18n.translate('topbar_settings'),
                  iconSize: isCompact ? 20 : 24,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (_) => const SettingsPanel(),
                    );
                  },
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: compact ? 18 : null,
      visualDensity: compact ? VisualDensity.compact : null,
      icon: Icon(icon),
    );
  }
}

enum _PdfToolsAction { watermark, split, merge, deletePages }

class _ToolsMenuItem extends StatelessWidget {
  const _ToolsMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
    );
  }
}

Future<void> _openDeletePagesDialog(
  BuildContext context,
  DocumentController controller,
) async {
  final i18n = AppLocalizations.of(context);
  final pageCount = await controller.getPdfPageCount();
  if (!context.mounted || pageCount <= 0) {
    return;
  }

  final pages = await showDialog<Set<int>>(
    context: context,
    builder: (_) => _DeletePagesDialog(pageCount: pageCount),
  );
  if (pages == null || pages.isEmpty || !context.mounted) {
    return;
  }
  if (pages.length >= pageCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(i18n.translate('error_no_pages_left')),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  await controller.deletePages(pages);
}

class _DeletePagesDialog extends StatefulWidget {
  const _DeletePagesDialog({required this.pageCount});

  final int pageCount;

  @override
  State<_DeletePagesDialog> createState() => _DeletePagesDialogState();
}

class _DeletePagesDialogState extends State<_DeletePagesDialog> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(i18n.translate('delete_pages_title')),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.translate('delete_pages_subtitle'),
              style: TextStyle(color: AppTheme.mutedInk),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.pageCount,
                  itemBuilder: (context, index) {
                    final page = index + 1;
                    return CheckboxListTile(
                      dense: true,
                      value: _selected.contains(page),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selected.add(page);
                          } else {
                            _selected.remove(page);
                          }
                        });
                      },
                      title: Text(
                        '${i18n.translate('delete_pages_page')} $page',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(i18n.translate('delete_pages_cancel')),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(Set<int>.from(_selected)),
          child: Text(i18n.translate('delete_pages_confirm')),
        ),
      ],
    );
  }
}
