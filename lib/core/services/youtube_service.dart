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
    final yt = YoutubeExplode();
    try {
      // Set android client for better stream compatibility
      final manifest = await yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.androidVr],
      );

      final audioStreams = manifest.audioOnly.toList()
        ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));

      if (audioStreams.isNotEmpty) {
        return audioStreams.first.url.toString();
      }

      // Fallback: muxed stream
      final muxed = manifest.muxed.withHighestBitrate();
      return muxed.url.toString();
    } catch (e) {
      print('[YoutubeService] Error: $e');
      return null;
    } finally {
      yt.close();
    }
  }

  void dispose() {
    _yt.close();
  }
}
