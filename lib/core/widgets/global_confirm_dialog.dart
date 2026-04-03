import 'package:flutter/material.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';

/// App-wide confirmation dialog. Returns `true` if the user confirms.
///
/// Styling follows [ThemeData.colorScheme] and [ThemeData.textTheme] for
/// correct light / dark appearance.
Future<bool> showGlobalConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = 'Cancel',
  String confirmText = 'Confirm',
  bool barrierDismissible = true,
  bool confirmIsDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: true,
    barrierColor: Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _GlobalConfirmDialog(
      title: title,
      message: message,
      cancelText: cancelText,
      confirmText: confirmText,
      confirmIsDestructive: confirmIsDestructive,
    ),
  );
  return result ?? false;
}

class _GlobalConfirmDialog extends StatelessWidget {
  const _GlobalConfirmDialog({
    required this.title,
    required this.message,
    required this.cancelText,
    required this.confirmText,
    required this.confirmIsDestructive,
  });

  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final bool confirmIsDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final dialogShape =
        theme.dialogTheme.shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        );

    final surface =
        theme.dialogTheme.backgroundColor ?? cs.surfaceContainerHigh;

    final confirmBg = confirmIsDestructive ? cs.error : cs.primary;
    final confirmFg = confirmIsDestructive ? cs.onError : cs.onPrimary;

    return AlertDialog(
      backgroundColor: surface,
      shape: dialogShape,
      title: Text(
        title,
        style: tt.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      content: Text(
        message,
        style: tt.bodyLarge?.copyWith(height: 1.4, color: cs.onSurfaceVariant),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
          child: Text(
            cancelText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: confirmBg,
            foregroundColor: confirmFg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
            ),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
