import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/services/audio_handler.dart';
import '../../data/models/video_model.dart';

class PlayerState {
  final VideoModel? currentVideo;
  final bool isPlaying;
  final bool isLoading;
  final String? error;
  final Duration position;
  final Duration duration;
  final List<VideoModel> queue;
  final int currentIndex;
  final bool isShuffled;
  final bool isRepeat;

  PlayerState({
    this.currentVideo,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.isShuffled = false,
    this.isRepeat = false,
  });

  /// BUG-03 fix: Use [clearError] flag to explicitly clear error.
  /// Without passing [error], the current value is preserved.
  /// Pass [clearError: true] to set error to null.
  /// Also added [clearCurrentVideo] for stop/reset scenarios.
  PlayerState copyWith({
    VideoModel? currentVideo,
    bool clearCurrentVideo = false,
    bool? isPlaying,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Duration? position,
    Duration? duration,
    List<VideoModel>? queue,
    int? currentIndex,
    bool? isShuffled,
    bool? isRepeat,
  }) {
    return PlayerState(
      currentVideo:
          clearCurrentVideo ? null : (currentVideo ?? this.currentVideo),
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      isRepeat: isRepeat ?? this.isRepeat,
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    final audioHandler = ref.read(audioHandlerProvider);

    // BUG-05 fix: Subscribe to position stream for real-time slider updates
    final positionSub = audioHandler.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    // BUG-05 fix: Subscribe to duration stream
    final durationSub = audioHandler.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    // BUG-02 fix: Sync isPlaying with actual audio player state
    final playingSub = audioHandler.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    // BUG-08 fix: Sync isLoading with processing state (buffering/loading)
    final processingSub = audioHandler.processingStateStream.listen((processingState) {
      final isBuffering = processingState == ProcessingState.loading || 
                          processingState == ProcessingState.buffering;
      
      state = state.copyWith(isLoading: isBuffering);
      
      // Auto-play next if completed
      if (processingState == ProcessingState.completed) {
        playNext();
      }
    });

    // Clean up subscriptions on provider dispose
    ref.onDispose(() {
      positionSub.cancel();
      durationSub.cancel();
      playingSub.cancel();
      processingSub.cancel();
    });

    return PlayerState();
  }

  AppAudioHandler get _handler => ref.read(audioHandlerProvider);

  /// Play a single video.
  Future<void> playVideo(VideoModel video) async {
    if (state.isLoading && state.currentVideo?.id == video.id) {
      print('[PlayerNotifier] Already loading this video, ignoring duplicate tap.');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      currentVideo: video,
      clearError: true,
      // Set initial duration from video model so UI shows it immediately
      // instead of staying at 00:00 until the audio stream loads
      duration: video.duration,
      position: Duration.zero,
    );
    try {
      await _handler.playFromVideoModel(video);
      // isPlaying will be updated by the stream listener (BUG-02 fix)
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, isPlaying: false, error: e.toString());
    }
  }

  /// BUG-07 fix: Play a video from a list and populate the queue.
  Future<void> playVideoFromList(
      VideoModel video, List<VideoModel> list) async {
    final index = list.indexWhere((v) => v.id == video.id);
    state = state.copyWith(
      queue: list,
      currentIndex: index >= 0 ? index : 0,
    );
    await playVideo(video);
  }

  /// Toggle play/pause. State is synced via stream listener.
  void togglePlayPause() {
    if (state.isPlaying) {
      _handler.pause();
    } else {
      _handler.play();
    }
  }

  /// Seek to a specific position.
  void seekTo(Duration pos) {
    _handler.seek(pos);
  }

  void addToQueue(VideoModel video) {
    state = state.copyWith(queue: [...state.queue, video]);
  }

  void toggleShuffle() =>
      state = state.copyWith(isShuffled: !state.isShuffled);
  void toggleRepeat() =>
      state = state.copyWith(isRepeat: !state.isRepeat);

  Future<void> playNext() async {
    if (state.queue.isEmpty) return;
    int nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) {
      if (state.isRepeat) {
        nextIndex = 0;
      } else {
        return;
      }
    }
    state = state.copyWith(currentIndex: nextIndex);
    await playVideo(state.queue[nextIndex]);
  }

  Future<void> playPrevious() async {
    if (state.queue.isEmpty) return;
    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      if (state.isRepeat) {
        prevIndex = state.queue.length - 1;
      } else {
        return;
      }
    }
    state = state.copyWith(currentIndex: prevIndex);
    await playVideo(state.queue[prevIndex]);
  }

  /// BUG-06 fix: Stop audio and fully reset player state.
  Future<void> stopAndReset() async {
    await _handler.stop();
    state = PlayerState();
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);

/// BUG-01 fix: Throw if not overridden in main.dart via AudioService.init().
final audioHandlerProvider = Provider<AppAudioHandler>((ref) {
  throw UnimplementedError(
    'audioHandlerProvider must be overridden in main.dart with AudioService.init()',
  );
});
