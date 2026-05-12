import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../data/models/video_model.dart';

class YoutubeService {
  final _yt = YoutubeExplode();

  Future<List<VideoModel>> searchVideos(String query) async {
    try {
      final searchList = await _yt.search.getVideos(query);
      return searchList.map<VideoModel>((video) => VideoModel(
        id: video.id.value,
        title: video.title,
        thumbnailUrl: video.thumbnails.mediumResUrl,
        channelName: video.author,
        durationInSeconds: video.duration?.inSeconds ?? 0,
      )).toList();
    } catch (e) {
      print('[YoutubeService] Search error: $e');
      return [];
    }
  }

  Future<String?> getAudioStreamUrl(String videoId) async {
    int retryCount = 0;
    const int maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        // Specify clients that are often more resilient to rate limits
        final manifest = await _yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: [
            YoutubeApiClient.android,
            YoutubeApiClient.ios,
            YoutubeApiClient.tv,
          ],
        );

        final m4aStream = manifest.audioOnly
            .where((s) => s.container.name == 'm4a')
            .toList();

        if (m4aStream.isNotEmpty) {
          return m4aStream.withHighestBitrate().url.toString();
        }

        if (manifest.audioOnly.isNotEmpty) {
          return manifest.audioOnly.withHighestBitrate().url.toString();
        }

        return null;
      } catch (e) {
        if (e.toString().contains('RequestLimitExceededException') ||
            e.toString().contains('429')) {
          print('[YoutubeService] Rate limit hit, retry ${retryCount + 1}/$maxRetries...');
          retryCount++;
          if (retryCount <= maxRetries) {
            await Future.delayed(Duration(seconds: 1 * retryCount));
            continue;
          }
        }
        print('[YoutubeService] ERROR getting stream URL: $e');
        return null;
      }
    }
    return null;
  }

  void dispose() {
    _yt.close();
  }
}
