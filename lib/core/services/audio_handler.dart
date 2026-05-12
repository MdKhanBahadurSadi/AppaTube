import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
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
    if (_isSettingSource) {
      print('[AudioHandler] Already setting source, ignoring duplicate request.');
      return;
    }
    _isSettingSource = true;

    try {
      print('[AudioHandler] Starting playback for: ${video.title}');
      
      final url = await _youtubeService.getAudioStreamUrl(video.id);
      
      if (url == null) {
        print('[AudioHandler] ERROR: Could not get stream URL');
        throw Exception('Failed to get audio stream. This might be due to YouTube rate limiting. Please try again later.');
      }

      final item = MediaItem(
        id: video.id,
        album: 'AppaTube',
        title: video.title,
        artist: video.channelName,
        artUri: Uri.parse(video.thumbnailUrl),
        duration: video.duration,
      );
      mediaItem.add(item);

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          headers: {
            'User-Agent': 'com.google.android.youtube/19.05.36 (Linux; U; Android 14; en_US; sdk_gphone64_x86_64; Build/UE1A.230829.036.A1; FW/1)',
            'X-YouTube-Client-Name': '3',
            'X-YouTube-Client-Version': '19.05.36',
            'Origin': 'https://www.youtube.com',
            'Referer': 'https://www.youtube.com/',
          },
        ),
      );
      play();
    } catch (e) {
      print('[AudioHandler] PLAYER ERROR: $e');
      rethrow;
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
