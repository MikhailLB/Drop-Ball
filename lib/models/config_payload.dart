class ConfigPayload {
  final bool accepted;
  final String? target;
  final String? note;
  final int? validUntil;

  const ConfigPayload._({
    required this.accepted,
    this.target,
    this.note,
    this.validUntil,
  });

  factory ConfigPayload.fromJson(Map<String, dynamic> raw) {
    return ConfigPayload._(
      accepted: raw['ok'] as bool? ?? false,
      target: raw['url'] as String?,
      note: raw['message'] as String?,
      validUntil: raw['expires'] as int?,
    );
  }

  factory ConfigPayload.refused(String reason) {
    return ConfigPayload._(accepted: false, note: reason);
  }
}
