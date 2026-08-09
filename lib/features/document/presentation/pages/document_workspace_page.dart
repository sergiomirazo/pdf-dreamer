import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
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
                  child: Column(
                    children: const [
                      WorkspaceTopBar(),
                      Expanded(
                        child: Row(
                          children: [
                            DocumentToolRail(),
                            Expanded(child: DocumentCanvas()),
                          ],
                        ),
                      ),
                    ],
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
