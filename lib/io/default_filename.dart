/// Builds a default filename with a timestamp suffix so saved exports do
/// not collide and can be sorted chronologically.
///
/// [base] is the descriptive prefix (e.g. 'scheduling_state', 'early_roster').
/// [extension] is the file extension without the leading dot (default 'txt').
/// [now] can be injected for testing; defaults to [DateTime.now].
String defaultExportFilename(
  String base, {
  String extension = 'txt',
  DateTime? now,
}) {
  final stamp = _formatTimestamp(now ?? DateTime.now());
  return '${base}_$stamp.$extension';
}

String _formatTimestamp(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)}_'
      '${two(dt.hour)}${two(dt.minute)}';
}
