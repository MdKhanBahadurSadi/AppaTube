import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerService {
  static String extractVideoId(String url) {
    // Already have video.id so this is just a utility
    return url;
  }

  static YoutubePlayerController createController(String videoId) {
    return YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        captionLanguage: 'en',
        forceHD: false,
        loop: false,
      ),
    );
  }
}
