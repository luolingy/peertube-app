import 'json_utils.dart';

/// Every paginated PeerTube endpoint answers with `{ total, data }`.
class PagedResult<T> {
  const PagedResult({required this.total, required this.data});

  final int total;
  final List<T> data;

  bool get isEmpty => data.isEmpty;

  static PagedResult<T> empty<T>() =>
      PagedResult<T>(total: 0, data: const <Never>[] as List<T>);

  /// Parses `{ total, data }`, applying [mapper] to each item.
  factory PagedResult.fromJson(dynamic json, T Function(Map<String, dynamic>) mapper) {
    final map = jsonMap(json);
    final total = jsonInt(map['total']);
    final data = jsonMapList(map['data']).map(mapper).toList(growable: false);
    return PagedResult<T>(total: total, data: data);
  }

  PagedResult<T> copyWith({int? total, List<T>? data}) =>
      PagedResult<T>(total: total ?? this.total, data: data ?? this.data);
}
