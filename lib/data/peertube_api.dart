import 'api_client.dart';
import 'api/actors_api.dart';
import 'api/comments_api.dart';
import 'api/playlists_api.dart';
import 'api/search_api.dart';
import 'api/server_api.dart';
import 'api/users_api.dart';
import 'api/videos_api.dart';
import 'api_section.dart';

/// The complete PeerTube API surface used by the application.
///
/// Endpoint groups live in `lib/data/api/` as mixins so that each file stays
/// focused while the call sites keep a single, discoverable entry point.
class PeertubeApi extends ApiSection
    with
        VideosApi,
        ActorsApi,
        CommentsApi,
        PlaylistsApi,
        SearchApi,
        UsersApi,
        ServerApi {
  PeertubeApi({required this.client});

  @override
  final ApiClient client;
}
