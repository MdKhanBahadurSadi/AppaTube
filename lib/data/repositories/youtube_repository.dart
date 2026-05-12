import '../../core/services/youtube_service.dart';
import '../models/video_model.dart';

/// Repository layer for YouTube operations.
/// Wraps [YoutubeService] to enable caching, testability, and separation of concerns.
class YoutubeRepository {
  final YoutubeService _service;

  YoutubeRepository(this._service);

  Future<List<VideoModel>> searchVideos(String query) {
    return _service.searchVideos(query);
  }

  Future<String?> getAudioStreamUrl(String videoId) {
    return _service.getAudioStreamUrl(videoId);
  }

  Future<VideoModel?> getVideoDetails(String videoId) {
    return _service.getVideoDetails(videoId);
  }

  void dispose() {
    _service.dispose();
  }
}
