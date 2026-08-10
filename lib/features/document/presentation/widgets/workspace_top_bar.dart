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
                    secondaryActiveColor: AppTheme.accent,
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
                          child: const CircularProgressIndicator(strokeWidth: 2),
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
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.sync_alt_rounded, size: isCompact ? 16 : 20),
                  label: Text(
                    document?.isMarkdown == true
                        ? i18n.translate('topbar_to_pdf')
                        : i18n.translate('topbar_to_md'),
                    style: TextStyle(fontSize: isCompact ? 12 : 14),
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: controller.isLoading ? null : controller.openDocument,
                  icon: controller.isLoading
                      ? SizedBox.square(
                          dimension: isCompact ? 14 : 18,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.folder_open_rounded, size: isCompact ? 16 : 20),
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
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
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
