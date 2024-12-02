import 'package:flutter/material.dart';
import 'main.dart'; // Import the main.dart file to access the global key
import 'generated/l10n.dart'; // Import the localization file

class UIHelper {
  static void showSnackBar(String message,
      {Duration duration = const Duration(seconds: 2)}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  static Future<bool?> showOverwriteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).fileAlreadyExistsTitle),
          content: Text(S.of(context).fileAlreadyExistsContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).noButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).yesButton),
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> showConfirmDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).confirmDeleteTitle),
          content: Text(S.of(context).confirmDeleteContent),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(S.of(context).cancelButton),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(S.of(context).deleteButton),
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> showMergeOrReplaceDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).importOptionsTitle),
          content: Text(S.of(context).mergeOrReplaceContent),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(S.of(context).mergeButton),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(S.of(context).replaceButton),
            ),
          ],
        );
      },
    );
  }
}
