class VersionResponse {
  final String status;
  final String lastVersion;
  final String versionId;
  final bool needUpdate;
  final bool availableUpdate;
  final bool reinstallNeed;

  const VersionResponse({
    required this.status,
    required this.lastVersion,
    required this.versionId,
    required this.needUpdate,
    required this.availableUpdate,
    required this.reinstallNeed,
  });

  factory VersionResponse.fromJson(Map<String, dynamic> json) {
    return VersionResponse(
      status: json['status'],
      lastVersion: json['last-version'],
      versionId: json['versionId'],
      needUpdate: json['needUpdate'],
      availableUpdate: json['availableUpdate'],
      reinstallNeed: json['reinstallNeed'],
    );
  }
}
