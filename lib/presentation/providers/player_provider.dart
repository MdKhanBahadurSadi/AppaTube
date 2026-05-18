import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/play_mode.dart';
import '../../core/constants/repeat_mode.dart';
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
  final RepeatMode repeatMode;
  final PlayMode playMode;

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
    this.repeatMode = RepeatMode.none,
    this.playMode = PlayMode.audio,
  });

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
    RepeatMode? repeatMode,
    PlayMode? playMode,
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
      repeatMode: repeatMode ?? this.repeatMode,
      playMode: playMode ?? this.playMode,
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    final audioHandler = ref.read(audioHandlerProvider);

    final positionSub = audioHandler.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    final durationSub = audioHandler.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    final playingSub = audioHandler.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    final processingSub = audioHandler.processingStateStream.listen((processingState) {
      final isBuffering = processingState == ProcessingState.loading || 
                          processingState == ProcessingState.buffering;
      
      state = state.copyWith(isLoading: isBuffering);
    });

    // Listen for song completion to handle auto-play/repeat
    final completionSub = audioHandler.songCompletedStream.listen((_) {
      onSongCompleted(audioHandler);
    });

    ref.onDispose(() {
      positionSub.cancel();
      durationSub.cancel();
      playingSub.cancel();
      processingSub.cancel();
      completionSub.cancel();
    });

    return PlayerState();
  }

  AppAudioHandler get _handler => ref.read(audioHandlerProvider);

  Future<void> playVideo(
    VideoModel video,
    AppAudioHandler handler, {
    PlayMode mode = PlayMode.audio,
  }) async {
    if (state.isLoading && state.currentVideo?.id == video.id) {
      return;
    }

    state = state.copyWith(
      playMode: mode,
      isLoading: true,
      currentVideo: video,
      clearError: true,
      duration: video.duration,
      position: Duration.zero,
    );
    try {
      if (mode == PlayMode.audio) {
        await handler.playFromVideoModel(video);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, isPlaying: false, error: e.toString());
    }
  }

  Future<void> playVideoFromList(
      VideoModel video, List<VideoModel> list) async {
    final index = list.indexWhere((v) => v.id == video.id);
    state = state.copyWith(
      queue: list,
      currentIndex: index >= 0 ? index : 0,
    );
    await playVideo(video, _handler);
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      _handler.pause();
    } else {
      _handler.play();
    }
  }

  void seekTo(Duration pos) {
    _handler.seek(pos);
  }

  void addToQueue(VideoModel video) {
    state = state.copyWith(queue: [...state.queue, video]);
  }

  void toggleShuffle() =>
      state = state.copyWith(isShuffled: !state.isShuffled);

  void cycleRepeatMode(AppAudioHandler handler) {
    final newMode = state.repeatMode.next();
    state = state.copyWith(repeatMode: newMode);
    handler.applyRepeatMode(newMode);
  }

  void togglePlayMode() {
    state = state.copyWith(
      playMode: state.playMode == PlayMode.audio
          ? PlayMode.video
          : PlayMode.audio,
    );
  }

  Future<void> playNext({AppAudioHandler? handler, bool isManual = true}) async {
    final queue = state.queue;
    if (queue.isEmpty) return;
    final h = handler ?? _handler;

    // Handle Repeat One: Only replay same song if it completed naturally (auto-play)
    // If the user clicks 'Next' manually, we should go to the next song regardless of Repeat One
    if (!isManual && state.repeatMode == RepeatMode.one && state.currentVideo != null) {
      await playVideo(state.currentVideo!, h, mode: state.playMode);
      return;
    }

    final nextIndex = state.currentIndex + 1;

    // If reached end of queue
    if (nextIndex >= queue.length) {
      if (state.repeatMode == RepeatMode.all) {
        // Go back to first song
        state = state.copyWith(currentIndex: 0);
        await playVideo(queue[0], h, mode: state.playMode);
      } else {
        // RepeatMode.none — stop playback
        await h.stop();
        state = state.copyWith(
          isPlaying: false,
          currentIndex: 0,
        );
      }
      return;
    }

    // Normal next
    state = state.copyWith(currentIndex: nextIndex);
    await playVideo(queue[nextIndex], h, mode: state.playMode);
  }

  Future<void> playPrevious({AppAudioHandler? handler, bool isManual = true}) async {
    final queue = state.queue;
    if (queue.isEmpty) return;
    final h = handler ?? _handler;

    // Similar logic for playPrevious and Repeat One
    if (!isManual && state.repeatMode == RepeatMode.one && state.currentVideo != null) {
      await playVideo(state.currentVideo!, h, mode: state.playMode);
      return;
    }

    final prevIndex = state.currentIndex - 1;

    if (prevIndex < 0) {
      if (state.repeatMode == RepeatMode.all) {
        // Go to last song
        final lastIndex = queue.length - 1;
        state = state.copyWith(currentIndex: lastIndex);
        await playVideo(queue[lastIndex], h, mode: state.playMode);
      } else {
        // Stay at first song, restart it
        await playVideo(queue[0], h, mode: state.playMode);
      }
      return;
    }

    state = state.copyWith(currentIndex: prevIndex);
    await playVideo(queue[prevIndex], h, mode: state.playMode);
  }

  Future<void> onSongCompleted(AppAudioHandler handler) async {
    // When a song completes naturally, we call playNext with isManual: false
    await playNext(handler: handler, isManual: false);
  }

  Future<void> stopAndReset() async {
    await _handler.stop();
    state = PlayerState();
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);

final audioHandlerProvider = Provider<AppAudioHandler>((ref) {
  throw UnimplementedError(
    'audioHandlerProvider must be overridden in main.dart with AudioService.init()',
  );
});
