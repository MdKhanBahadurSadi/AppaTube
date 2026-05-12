import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../app/routes.dart';
import '../../core/constants/play_mode.dart';
import '../../core/services/video_player_service.dart';
import '../providers/player_provider.dart';
import '../widgets/play_mode_toggle.dart';
import '../widgets/video_card.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  YoutubePlayerController? _videoController;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    final video = ref.read(playerProvider).currentVideo;
    if (video != null) {
      _videoController = VideoPlayerService.createController(video.id);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final video = playerState.currentVideo;

    if (video == null || _videoController == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE40000),
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        setState(() {
          _isFullScreen = true;
        });
      },
      onExitFullScreen: () {
        setState(() {
          _isFullScreen = false;
        });
      },
      player: YoutubePlayer(
        controller: _videoController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFE40000),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFFE40000),
          handleColor: Color(0xFFFF4444),
          bufferedColor: Color(0xFF444444),
          backgroundColor: Color(0xFF1A1A1A),
        ),
        onReady: () {
          _videoController!.play();
        },
        onEnded: (data) {
          // auto play next if queue exists
          ref.read(playerProvider.notifier).playNext(ref.read(audioHandlerProvider));
        },
      ),
      builder: (context, player) {
        return WillPopScope(
          onWillPop: () async {
            _videoController?.pause();
            return true;
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            body: Column(
              children: [
                player,
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Video info section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    video.channelName,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Views placeholder',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const Divider(color: Color(0xFF1E1E1E), height: 32),

                              // Mode toggle row
                              Row(
                                children: [
                                  const Text(
                                    'Playing as:',
                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  PlayModeToggle(
                                    currentMode: playerState.playMode,
                                    onModeChanged: (mode) {
                                      if (mode == PlayMode.audio) {
                                        // Switch to audio mode:
                                        // 1. Pause video
                                        _videoController?.pause();
                                        // 2. Start audio via handler
                                        ref.read(playerProvider.notifier).togglePlayMode();
                                        final handler = ref.read(audioHandlerProvider);
                                        handler.playFromVideoModel(playerState.currentVideo!);
                                        // 3. Navigate back to home
                                        Navigator.pushReplacementNamed(context, Routes.home);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),

                        // Audio mode warning banner
                        if (playerState.playMode == PlayMode.video)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A0A),
                              border: Border.all(color: const Color(0xFFE40000).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Color(0xFFE40000), size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Video mode keeps screen on. Switch to Audio for background play.',
                                    style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Up Next / Queue section
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'Up Next',
                            style: TextStyle(
                              color: Color(0xFFE40000),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: playerState.queue.length > 5 ? 5 : playerState.queue.length,
                          itemBuilder: (context, index) {
                            final queueVideo = playerState.queue[index];
                            return VideoCard(
                              video: queueVideo,
                              heroContext: 'video_player_queue',
                              isPlaying: queueVideo.id == video.id,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
