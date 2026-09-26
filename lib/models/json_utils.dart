/// Defensive JSON helpers.
///
/// PeerTube payloads are mostly stable but a few fields are optional or change
/// type between versions (some are `null` for federated/unknown values). These
/// helpers keep the model layer tolerant and readable.
library;

Map<String, dynamic> jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    final result = <String, dynamic>{};
    value.forEach((dynamic key, dynamic v) => result[key.toString()] = v);
    return result;
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> jsonMapList(dynamic value) {
  if (value is List) {
    return value
        .map(jsonMap)
        .where((Map<String, dynamic> e) => e.isNotEmpty)
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

List<String> jsonStringList(dynamic value) {
  if (value is List) {
    return value
        .where((dynamic e) => e != null)
        .map((dynamic e) => e.toString())
        .toList(growable: false);
  }
  return const <String>[];
}

List<int> jsonIntList(dynamic value) {
  if (value is List) {
    return value
        .map((dynamic e) => jsonIntOrNull(e))
        .whereType<int>()
        .toList(growable: false);
  }
  return const <int>[];
}

int jsonInt(dynamic value, [int fallback = 0]) => jsonIntOrNull(value) ?? fallback;

int? jsonIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double jsonDouble(dynamic value, [double fallback = 0]) => jsonDoubleOrNull(value) ?? fallback;

double? jsonDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String jsonString(dynamic value, [String fallback = '']) => jsonStringOrNull(value) ?? fallback;

String? jsonStringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

bool jsonBool(dynamic value, [bool fallback = false]) => jsonBoolOrNull(value) ?? fallback;

bool? jsonBoolOrNull(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return null;
}

DateTime? jsonDate(dynamic value) {
  final raw = jsonStringOrNull(value);
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}
