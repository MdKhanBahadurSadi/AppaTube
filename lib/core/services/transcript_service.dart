import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TranscriptService {
  
  Future<String?> getTranscript(String videoId) async {
    final yt = YoutubeExplode();
    try {
      final trackManifest = await yt.videos.closedCaptions
          .getManifest(videoId);
      
      if (trackManifest.tracks.isEmpty) return null;

      // Prefer English, fallback to first available
      final track = trackManifest.tracks.firstWhere(
        (t) => t.language.code == 'en',
        orElse: () => trackManifest.tracks.first,
      );

      final closedCaptions = await yt.videos.closedCaptions.get(track);
      
      // Build full transcript text with timestamps
      final buffer = StringBuffer();
      for (final caption in closedCaptions.captions) {
        final time = caption.offset;
        final minutes = time.inMinutes;
        final seconds = time.inSeconds % 60;
        buffer.writeln('[${minutes}:${seconds.toString().padLeft(2,'0')}] ${caption.text}');
      }
      
      return buffer.toString();
    } catch (e) {
      print('[TranscriptService] Error: $e');
      return null;
    } finally {
      yt.close();
    }
  }

  // Returns list of {time, text} maps for timestamp features
  Future<List<Map<String, dynamic>>> getTimedCaptions(
      String videoId) async {
    final yt = YoutubeExplode();
    try {
      final trackManifest = await yt.videos.closedCaptions
          .getManifest(videoId);
      if (trackManifest.tracks.isEmpty) return [];

      final track = trackManifest.tracks.firstWhere(
        (t) => t.language.code == 'en',
        orElse: () => trackManifest.tracks.first,
      );

      final closedCaptions = await yt.videos.closedCaptions.get(track);
      
      return closedCaptions.captions.map((c) => {
        'offsetSeconds': c.offset.inSeconds,
        'text': c.text,
      }).toList();
    } catch (e) {
      return [];
    } finally {
      yt.close();
    }
  }
}

final transcriptServiceProvider = Provider<TranscriptService>(
  (ref) => TranscriptService(),
);
