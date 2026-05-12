import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeAudioSource extends StreamAudioSource {
  final StreamInfo streamInfo;
  final YoutubeExplode _yt = YoutubeExplode();

  YoutubeAudioSource(this.streamInfo);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // Range is not directly supported in the simple get method of 3.x
    // We will return the full stream for now to bypass the 403 error
    final stream = _yt.videos.streamsClient.get(streamInfo);
    
    final String contentType = streamInfo.container.name == 'm4a' 
        ? 'audio/mp4' 
        : 'video/webm';

    return StreamAudioResponse(
      sourceLength: streamInfo.size.totalBytes,
      contentLength: streamInfo.size.totalBytes,
      offset: 0,
      stream: stream,
      contentType: contentType,
    );
  }
}
