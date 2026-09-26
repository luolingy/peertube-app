import 'package:flutter/foundation.dart';

import '../models/paged.dart';

/// Loads one page of a paginated endpoint.
typedef PageLoader<T> = Future<PagedResult<T>> Function(int start, int count);

/// A generic, reusable pagination controller.
///
/// Handles the initial load, "load more" on scroll, pull to refresh, error
/// reporting and optimistic local mutations (used after create/delete).
class PagedListController<T> extends ChangeNotifier {
  PagedListController({required PageLoader<T> loader, this.pageSize = 20})
      : _loader = loader;

  PageLoader<T> _loader;  final int pageSize;

  final List<T> _items = <T>[];
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;
  int _generation = 0;
  bool _disposed = false;

  /// Items loaded so far.
  List<T> get items => _items;

  /// Total number of items reported by the server.
  int get total => _total;

  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  Object? get error => _error;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// True while the very first page is being fetched.
  bool get isInitialLoading => _loading && _items.isEmpty;

  /// True when the list finished loading and has nothing to show.
  bool get isEmptyAfterLoad => !_loading && _error == null && _items.isEmpty;

  /// Replaces the loader (used when filters change).
  void setLoader(PageLoader<T> loader, {bool reload = true}) {
    _loader = loader;
    if (reload) refresh();
  }

  /// Loads the first page, replacing the current content.
  Future<void> refresh() async {
    final generation = ++_generation;
    _loading = true;
    _error = null;
    _notify();

    try {
      final page = await _loader(0, pageSize);
      if (generation != _generation || _disposed) return;
      _items
        ..clear()
        ..addAll(page.data);
      _total = page.total;
      _hasMore = _computeHasMore(page, _items.length);
    } catch (error) {
      if (generation != _generation || _disposed) return;
      _error = error;
      _hasMore = false;
    } finally {
      if (generation == _generation && !_disposed) {
        _loading = false;
        _notify();
      }
    }
  }

  /// Appends the next page.
  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;

    final generation = _generation;
    _loadingMore = true;
    _notify();

    try {
      final page = await _loader(_items.length, pageSize);
      if (generation != _generation || _disposed) return;
      _items.addAll(page.data);
      _total = page.total;
      _hasMore = _computeHasMore(page, _items.length);
    } catch (error) {
      if (generation != _generation || _disposed) return;
      _error = error;
      _hasMore = false;
    } finally {
      if (generation == _generation && !_disposed) {
        _loadingMore = false;
        _notify();
      }
    }
  }

  bool _computeHasMore(PagedResult<T> page, int loaded) {
    if (page.data.isEmpty) return false;
    if (page.data.length < pageSize) return false;
    if (page.total > 0 && loaded >= page.total) return false;
    return true;
  }

  /// Replaces the whole content (used after a mutation that invalidates it).
  void replaceAll(List<T> items, {int? total}) {
    _items
      ..clear()
      ..addAll(items);
    if (total != null) _total = total;
    _hasMore = _items.length < _total;
    _error = null;
    _notify();
  }

  void insertAt(int index, T item) {
    final safeIndex = index.clamp(0, _items.length);
    _items.insert(safeIndex, item);
    _total += 1;
    _notify();
  }

  void insertFirst(T item) => insertAt(0, item);

  void removeWhere(bool Function(T item) test) {
    final before = _items.length;
    _items.removeWhere(test);
    final removed = before - _items.length;
    if (removed == 0) return;
    _total = (_total - removed).clamp(0, 1 << 62);
    _notify();
  }

  void updateWhere(bool Function(T item) test, T Function(T item) update) {
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      if (test(_items[i])) {
        _items[i] = update(_items[i]);
        changed = true;
      }
    }
    if (changed) _notify();
  }

  /// Ensures the list is loaded at least once.
  Future<void> ensureLoaded() async {
    if (_items.isEmpty && !_loading) await refresh();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
