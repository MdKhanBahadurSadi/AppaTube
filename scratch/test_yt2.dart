import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  print('Headers used:');
  // I need to find the property that contains the headers or user agent
  // Let's just print a video stream URL and test it.
  try {
    final manifest = await yt.videos.streamsClient.getManifest('o-AAI3cC7mJYfnsOuZ_RBH1L_TzeInqlG5omx8Onolzjcp');
    if (manifest.audioOnly.isNotEmpty) {
      print('URL: ${manifest.audioOnly.withHighestBitrate().url}');
    }
  } catch(e) {
    print('error $e');
  }
}
