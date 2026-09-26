import 'api_client.dart';

/// Base class for the endpoint groups mixed into [PeertubeApi].
abstract class ApiSection {
  ApiClient get client;
}

/// Encodes a list of values the way PeerTube expects array query parameters
/// (comma separated, e.g. `categoryOneOf=1,2`).
String? csv(Iterable<Object?>? values) {
  if (values == null) return null;
  final list = values
      .where((Object? v) => v != null)
      .map((Object? v) => v.toString())
      .where((String v) => v.isNotEmpty)
      .toList(growable: false);
  if (list.isEmpty) return null;
  return list.join(',');
}
