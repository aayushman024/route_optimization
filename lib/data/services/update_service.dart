import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:route_optimization/core/constants/changelogs.dart';
import 'package:route_optimization/core/dialogs/changelog_dialog.dart';

class UpdateService {
  static const String _lastSeenPatchKey = "last_seen_patch_number";

  Future<void> checkForUpdateChangelog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get the last seen patch number, default to 0 if never seen
    final int lastSeenPatch = prefs.getInt(_lastSeenPatchKey) ?? 0;
    
    // The current patch version from constants
    final int currentPatch = AppChangelog.currentPatchNumber;

    // If the active patch is newer than the one stored, show the dialog
    if (currentPatch > lastSeenPatch) {
      // Small delay to ensure the UI is fully rendered before showing dialog
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false, // Force them to press "Awesome!"
        builder: (context) {
          return ChangelogDialog(changelog: AppChangelog.currentUpdate);
        },
      );

      // Save the patch number so it never shows again for this patch
      await prefs.setInt(_lastSeenPatchKey, currentPatch);
    }
  }
}
