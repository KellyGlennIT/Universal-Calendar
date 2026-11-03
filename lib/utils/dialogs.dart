import 'package:flutter/material.dart';
import '../l10n/tr.dart';

/// Consistent destructive-action confirmation dialog used across the app.
///
/// Returns `true` if the user tapped Delete, `false` if they cancelled or
/// dismissed by tapping outside. Callers should guard the destructive action
/// with `if (confirmed && context.mounted)`.
Future<bool> confirmDelete(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(tr(dialogContext, 'Delete')),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(tr(dialogContext, 'Cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(tr(dialogContext, 'Delete')),
        ),
      ],
    ),
  );
  return result ?? false;
}