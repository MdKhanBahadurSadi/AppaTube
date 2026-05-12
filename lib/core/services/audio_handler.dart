import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../data/models/video_model.dart';
import 'youtube_service.dart';

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeService _youtubeService;
  bool _isSettingSource = false;

  AppAudioHandler(this._youtubeService) {
    _notifyAudioHandlerAboutPlaybackEvents();
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[state.processingState]!,
        playing: state.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });

    _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item == null) return;
      mediaItem.add(item.copyWith(duration: duration));
    });
  }

  // Exposed streams for UI
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<ProcessingState> get processingStateStream => _player.playerStateStream.map((s) => s.processingState);

  Future<void> playFromVideoModel(VideoModel video) async {
    if (_isSettingSource) return;
    _isSettingSource = true;

    try {
      mediaItem.add(MediaItem(
        id: video.id,
        album: 'AppaTube',
        title: video.title,
        artist: video.channelName,
        artUri: Uri.parse(video.thumbnailUrl),
        duration: video.duration,
      ));

      final yt = YoutubeExplode();
      try {
        // Use androidVr client for better compatibility
        final manifest = await yt.videos.streamsClient.getManifest(
          video.id,
          ytClients: [YoutubeApiClient.androidVr],
        );

        final audioStreams = manifest.audioOnly.toList()
          ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));

        if (audioStreams.isEmpty) {
          print('[AudioHandler] No audio streams found for ${video.id}');
          return;
        }

        final streamInfo = audioStreams.first;
        final streamUrl = streamInfo.url.toString();

        // Use LockCachingAudioSource for proper byte-range support and Android User-Agent to bypass 403
        await _player.setAudioSource(
          LockCachingAudioSource(
            Uri.parse(streamUrl),
            headers: {
              'User-Agent': 'com.google.android.youtube/17.36.4 (Linux; U; Android 12; GB) gzip',
              'Referer': 'https://www.youtube.com/',
            },
          ),
        );

        await _player.play();
      } finally {
        yt.close();
      }
    } catch (e) {
      print('[AudioHandler] Error: $e');
      // Fallback to direct AudioSource.uri if LockCachingAudioSource fails
      try {
        final streamUrl = await _youtubeService.getAudioStreamUrl(video.id);
        if (streamUrl != null) {
          await _player.setAudioSource(
            AudioSource.uri(
              Uri.parse(streamUrl),
              headers: {
                'User-Agent': 'com.google.android.youtube/17.36.4 (Linux; U; Android 12; GB) gzip',
                'Referer': 'https://www.youtube.com/',
              },
            ),
          );
          await _player.play();
        }
      } catch (fallbackError) {
        print('[AudioHandler] Fallback error: $fallbackError');
      }
    } finally {
      _isSettingSource = false;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();
}
