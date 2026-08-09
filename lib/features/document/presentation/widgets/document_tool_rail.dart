import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/document_tool.dart';
import '../controllers/document_controller.dart';

class DocumentToolRail extends StatelessWidget {
  const DocumentToolRail({super.key});

  static const List<Color> _brushColors = [
    AppTheme.primary,
    AppTheme.accent,
    Color(0xFF111827),
    Color(0xFF00A896),
    Color(0xFFE63946),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentController>();
    final i18n = AppLocalizations.of(context);

    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _ToolButton(
              icon: Icons.near_me_rounded,
              tooltip: i18n.translate('tool_select'),
              isSelected: controller.tool == DocumentTool.select,
              onPressed: () => controller.selectTool(DocumentTool.select),
            ),
            _ToolButton(
              icon: Icons.draw_rounded,
              tooltip: i18n.translate('tool_brush'),
              isSelected: controller.tool == DocumentTool.brush,
              onPressed: () => controller.selectTool(DocumentTool.brush),
            ),
            PopupMenuButton<Color>(
              tooltip: i18n.translate('tool_brush_color'),
              icon: Icon(Icons.palette_rounded, color: controller.brushColor),
              onSelected: controller.setBrushColor,
              itemBuilder: (context) {
                return [
                  for (final color in _brushColors)
                    PopupMenuItem<Color>(
                      value: color,
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.border),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(i18n.translate(_colorKey(color))),
                        ],
                      ),
                    ),
                ];
              },
            ),
            RotatedBox(
              quarterTurns: 3,
              child: SizedBox(
                width: 92,
                child: Slider(
                  value: controller.brushWidth,
                  min: 1,
                  max: 16,
                  divisions: 15,
                  activeColor: AppTheme.primary,
                  label: controller.brushWidth.round().toString(),
                  onChanged: controller.setBrushWidth,
                ),
              ),
            ),
            _ToolButton(
              icon: Icons.add_photo_alternate_rounded,
              tooltip: i18n.translate('tool_image'),
              isSelected: controller.tool == DocumentTool.imageSignature,
              onPressed: controller.hasDocument
                  ? () => controller.selectTool(DocumentTool.imageSignature)
                  : null,
            ),
            const Divider(height: 28, indent: 14, endIndent: 14),
            _ToolButton(
              icon: Icons.undo_rounded,
              tooltip: i18n.translate('tool_undo'),
              onPressed: controller.canUndo ? controller.undo : null,
            ),
            _ToolButton(
              icon: Icons.redo_rounded,
              tooltip: i18n.translate('tool_redo'),
              onPressed: controller.canRedo ? controller.redo : null,
            ),
            const SizedBox(height: 14),
            _ToolButton(
              icon: Icons.check_rounded,
              tooltip: i18n.translate('tool_fix_image'),
              onPressed: controller.selectedStampId != null
                  ? controller.fixSelectedStamp
                  : null,
            ),
            _ToolButton(
              icon: Icons.delete_outline_rounded,
              tooltip: i18n.translate('tool_delete_image'),
              onPressed: controller.selectedStampId != null
                  ? controller.deleteSelectedStamp
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  static String _colorKey(Color color) {
    if (color == AppTheme.primary) {
      return 'color_primary';
    }
    if (color == AppTheme.accent) {
      return 'color_accent';
    }
    if (color == const Color(0xFF111827)) {
      return 'color_black';
    }
    if (color == const Color(0xFF00A896)) {
      return 'color_green';
    }
    if (color == const Color(0xFFE63946)) {
      return 'color_red';
    }
    return 'color_default';
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.isSelected = false,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: IconButton(
        tooltip: tooltip,
        isSelected: isSelected,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primary : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : AppTheme.ink,
          disabledForegroundColor: AppTheme.mutedInk.withValues(alpha: 0.35),
        ),
        icon: Icon(icon),
      ),
    );
  }
}
