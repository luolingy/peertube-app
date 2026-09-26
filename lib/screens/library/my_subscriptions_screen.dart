import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/actor.dart';
import '../../models/video.dart';
import '../../state/paged_list_controller.dart';
import '../../widgets/actor_tiles.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/video_cards.dart';

/// Subscribed channels and their latest videos.
class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  late final PagedListController<VideoChannel> _channels;
  late final PagedListController<Video> _videos;
  String _sort = '-createdAt';

  @override
  void initState() {
    super.initState();
    final api = context.read<PeertubeApi>();
    _channels = PagedListController<VideoChannel>(
      loader: (int start, int count) => api.listMySubscriptions(
        start: start,
        count: count,
        sort: '-createdAt',
      ),
    );
    _videos = PagedListController<Video>(
      loader: (int start, int count) => api.listSubscriptionVideos(
        start: start,
        count: count,
        sort: _sort,
      ),
    );
  }

  @override
  void dispose() {
    _channels.dispose();
    _videos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的订阅'),
          actions: <Widget>[
            PopupMenuButton<String>(
              tooltip: '视频排序',
              initialValue: _sort,
              onSelected: (String value) {
                setState(() => _sort = value);
                _videos.setLoader(
                  (int start, int count) => api.listSubscriptionVideos(
                    start: start,
                    count: count,
                    sort: value,
                  ),
                );
              },
              itemBuilder: (BuildContext context) => kSubscriptionsSorts
                  .map(
                    (OptionItem option) => PopupMenuItem<String>(
                      value: option.value,
                      child: Text(option.label),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: '最新视频'),
              Tab(text: '已订阅频道'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            VideoGrid(
              controller: _videos,
              baseUrl: baseUrl,
              emptyTitle: '订阅的频道还没有新视频',
            ),
            PagedListView<VideoChannel>(
              controller: _channels,
              padding: const EdgeInsets.symmetric(vertical: 8),
              emptyTitle: '还没有订阅任何频道',
              emptyIcon: Icons.subscriptions_outlined,
              itemBuilder: (BuildContext context, VideoChannel channel, int index) =>
                  ChannelListTile(channel: channel, baseUrl: baseUrl),
            ),
          ],
        ),
      ),
    );
  }
}
