class ServerResponse {
  final bool accepted;
  final String? target;
  final String? note;
  final int? validUntil;

  const ServerResponse._({
    required this.accepted,
    this.target,
    this.note,
    this.validUntil,
  });

  factory ServerResponse.fromJson(Map<String, dynamic> raw) {
    return ServerResponse._(
      accepted: raw['ok'] as bool? ?? false,
      target: raw['url'] as String?,
      note: raw['message'] as String?,
      validUntil: raw['expires'] as int?,
    );
  }

  factory ServerResponse.refused(String reason) {
    return ServerResponse._(accepted: false, note: reason);
  }
}
