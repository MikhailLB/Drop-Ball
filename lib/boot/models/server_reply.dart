class ServerReply {
  final bool ok;
  final String? url;
  final String? note;
  final int? expires;

  ServerReply({required this.ok, this.url, this.note, this.expires});

  factory ServerReply.fromJson(Map<String, dynamic> j) => ServerReply(
    ok:      j['ok'] as bool? ?? false,
    url:     j['url'] as String?,
    note:    j['message'] as String?,
    expires: j['expires'] as int?,
  );

  factory ServerReply.fail(String reason) =>
      ServerReply(ok: false, note: reason);
}
