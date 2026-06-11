# route_optimization

A mobile app for field executives of mNivesh

Release and patch commands for shorebird for this project:
release: shorebird release android-apk '--' --no-tree-shake-icons
patch: shorebird patch android '--' --no-tree-shake-icons

Every time you deploy a Shorebird patch:

Open lib/core/constants/changelogs.dart.
Increment currentPatchNumber (e.g. from 1 to 2).
Update the newFeatures list with your release notes.
Run your shorebird patch android command.
Users will instantly see the new dialog exactly once the next time they open the dashboard!

