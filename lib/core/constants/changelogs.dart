import 'package:route_optimization/data/models/update_changelog_model.dart';

class AppChangelog {
  // Update this patch number manually every time you send a Shorebird patch
  static const int currentPatchNumber = 1;
  static const String currentVersion = "1.1.1+3";

  // The changelog details for the current patch
  static const UpdateChangelog currentUpdate = UpdateChangelog(
    patchNumber: currentPatchNumber,
    version: currentVersion,
    newFeatures: [
   "You can now see your previously completed tasks by going to >App Drawer(top left) -> Completed Tasks"
    ],
  );
}
