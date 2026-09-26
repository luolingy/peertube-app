/// Small formatting helpers shared across the UI.
///
/// Everything is written by hand (instead of pulling `intl`) to keep the
/// dependency surface small and to get Chinese-friendly number formatting.
library;

/// `3725` -> `1:02:05`, `125` -> `2:05`.
String formatDuration(int? seconds) {
  if (seconds == null || seconds <= 0) return '0:00';

  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;

  if (h > 0) {
    return '$h:${_pad(m)}:${_pad(s)}';
  }
  return '$m:${_pad(s)}';
}

/// `3725` -> `1 小时 2 分钟` (used for a video's total length).
String formatLongDuration(int? seconds) {
  if (seconds == null || seconds <= 0) return '0 秒';

  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;

  final parts = <String>[];
  if (h > 0) parts.add('$h 小时');
  if (m > 0) parts.add('$m 分钟');
  if (h == 0 && m == 0) parts.add('$s 秒');
  return parts.join(' ');
}

/// Compact, Chinese-aware count: `12345` -> `1.2万`.
String formatCount(int? value) {
  final n = value ?? 0;
  if (n.abs() < 1000) return '$n';

  if (n.abs() >= 100000000) {
    return '${(n / 100000000).toStringAsFixed(1)}亿';
  }
  if (n.abs() >= 10000) {
    return '${(n / 10000).toStringAsFixed(1)}万';
  }
  return '${(n / 1000).toStringAsFixed(1)}k';
}

/// `1234567` -> `1.2 MB`.
String formatBytes(int? bytes) {
  final n = (bytes ?? 0).toDouble();
  if (n < 1024) return '${n.toStringAsFixed(0)} B';

  const units = ['KB', 'MB', 'GB', 'TB', 'PB'];
  var value = n / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
}

/// "3 分钟前" style relative time.
String formatRelativeTime(DateTime? time, {DateTime? now}) {
  if (time == null) return '';

  final reference = now ?? DateTime.now();
  final local = time.toLocal();
  final diff = reference.difference(local);

  if (diff.isNegative) return '刚刚';
  if (diff.inSeconds < 45) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 30) return '${diff.inDays} 天前';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} 个月前';
  return '${(diff.inDays / 365).floor()} 年前';
}

/// `2026-09-25`
String formatDate(DateTime? time) {
  if (time == null) return '';
  final d = time.toLocal();
  return '${d.year}-${_pad(d.month)}-${_pad(d.day)}';
}

/// `2026-09-25 12:51`
String formatDateTime(DateTime? time) {
  if (time == null) return '';
  final d = time.toLocal();
  return '${formatDate(d)} ${_pad(d.hour)}:${_pad(d.minute)}';
}

/// `1.2 万次观看` style label.
String formatWatchCount(int? views) => '${formatCount(views)} 次观看';

/// `2.3 MB/s`
String formatSpeed(double? bytesPerSecond) =>
    bytesPerSecond == null ? '' : '${formatBytes(bytesPerSecond.round())}/s';

String _pad(int v) => v.toString().padLeft(2, '0');
