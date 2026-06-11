class UpdateChangelog {
  final int patchNumber;
  final String version;
  final List<String> newFeatures;

  const UpdateChangelog({
    required this.patchNumber,
    required this.version,
    required this.newFeatures,
  });
}
