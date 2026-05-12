import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Searching...');
    final searchResult = await yt.search.search('flutter demo');
    final firstVideo = searchResult.first;
    print('Found: ${firstVideo.title} (ID: ${firstVideo.id.value})');

    print('Getting manifest...');
    final manifest = await yt.videos.streamsClient.getManifest(firstVideo.id.value);
    
    print('Audio only streams: ${manifest.audioOnly.length}');
    if (manifest.audioOnly.isNotEmpty) {
      print('Highest bitrate audio: ${manifest.audioOnly.withHighestBitrate().url}');
    }

    print('Muxed streams: ${manifest.muxed.length}');
    if (manifest.muxed.isNotEmpty) {
      print('Highest bitrate muxed: ${manifest.muxed.withHighestBitrate().url}');
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
