import 'package:flutter/material.dart';

import '../state/paged_list_controller.dart';
import 'state_views.dart';

/// Renders a [PagedListController] as a scrollable list or grid.
///
/// Takes care of the initial load, infinite scrolling, pull to refresh and the
/// empty/error/loading states so that screens only describe how one item looks.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.gridDelegate,
    this.header,
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyTitle = '暂无内容',
    this.emptySubtitle,
    this.emptyAction,
    this.onRefresh,
    this.controller2,
    this.physics,
  });

  final PagedListController<T> controller;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry padding;

  /// When provided, items are laid out in a grid.
  final SliverGridDelegate? gridDelegate;
  final Widget? header;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final Widget? emptyAction;
  final Future<void> Function()? onRefresh;

  /// Alias kept for readability at the call site.
  final ScrollController? controller2;
  final ScrollPhysics? physics;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.ensureLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant PagedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.ensureLoaded();
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 480) {
      widget.controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final custom = widget.onRefresh;
    if (custom != null) {
      await custom();
    } else {
      await widget.controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final controller = widget.controller;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: widget.physics ??
                const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: <Widget>[
              if (widget.header != null)
                SliverToBoxAdapter(child: widget.header),
              if (controller.isInitialLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingView(),
                )
              else if (controller.error != null && controller.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    error: controller.error,
                    onRetry: controller.refresh,
                  ),
                )
              else if (controller.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(
                    icon: widget.emptyIcon,
                    title: widget.emptyTitle,
                    subtitle: widget.emptySubtitle,
                    action: widget.emptyAction,
                  ),
                )
              else ...<Widget>[
                if (widget.gridDelegate != null)
                  SliverPadding(
                    padding: widget.padding,
                    sliver: SliverGrid(
                      gridDelegate: widget.gridDelegate!,
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) => widget.itemBuilder(
                          context,
                          controller.items[index],
                          index,
                        ),
                        childCount: controller.items.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: widget.padding,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) => widget.itemBuilder(
                          context,
                          controller.items[index],
                          index,
                        ),
                        childCount: controller.items.length,
                      ),
                    ),
                  ),
                if (controller.isLoadingMore)
                  const SliverToBoxAdapter(child: FooterLoader())
                else if (!controller.hasMore)
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ],
          ),
        );
      },
    );
  }
}
