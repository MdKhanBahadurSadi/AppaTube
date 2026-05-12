import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../providers/player_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    // Initial check for rotation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPlaying = ref.read(playerProvider).isPlaying;
      if (isPlaying) {
        _rotationController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final video = playerState.currentVideo;

    if (video == null) return const Scaffold(body: Center(child: Text('No Video Selected')));

    // Sync rotation animation with playback state
    if (playerState.isPlaying) {
      if (!_rotationController.isAnimating) _rotationController.repeat();
    } else {
      if (_rotationController.isAnimating) _rotationController.stop();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Top bar row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.expand_more, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 3. Album art section
                Center(
                  child: RotationTransition(
                    turns: _rotationController,
                    child: Hero(
                      tag: 'thumbnail_${video.id}',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: playerState.isPlaying ? 260 : 220,
                        height: playerState.isPlaying ? 260 : 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(playerState.isPlaying ? 130 : 20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE40000).withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(playerState.isPlaying ? 130 : 20),
                          child: CachedNetworkImage(
                            imageUrl: video.thumbnailUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // 4. Song info row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              video.channelName,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white60),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. Progress section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.red,
                          inactiveTrackColor: AppColors.surfaceHigh,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 3,
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        ),
                        child: Slider(
                          value: playerState.position.inSeconds.toDouble(),
                          max: playerState.duration.inSeconds.toDouble(),
                          onChanged: (val) {
                            playerNotifier.seekTo(Duration(seconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatDuration(playerState.position),
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            Text(
                              formatDuration(playerState.duration),
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 6. Controls row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: playerState.isShuffled ? AppColors.red : Colors.white38,
                        ),
                        onPressed: () => playerNotifier.toggleShuffle(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                        onPressed: () => playerNotifier.playPrevious(),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => playerNotifier.togglePlayPause(),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.red, Color(0xFF8B0000)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.red.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Icon(
                            playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                        onPressed: () => playerNotifier.playNext(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          Icons.repeat_rounded,
                          color: playerState.isRepeat ? AppColors.red : Colors.white38,
                        ),
                        onPressed: () => playerNotifier.toggleRepeat(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 7. Volume row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down, color: Colors.white38, size: 20),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white38,
                            inactiveTrackColor: AppColors.surfaceHigh,
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                            trackHeight: 2,
                          ),
                          child: Slider(
                            value: 0.7, // Mock volume value
                            onChanged: (val) {},
                          ),
                        ),
                      ),
                      const Icon(Icons.volume_up, color: Colors.white38, size: 20),
                    ],
                  ),
                ),

                // 8. Queue section
                if (playerState.queue.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'UP NEXT',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: playerState.queue.length,
                      itemBuilder: (context, index) {
                        final qVideo = playerState.queue[index];
                        final isCurrent = qVideo.id == video.id;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.red.withOpacity(0.2) : AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(20),
                            border: isCurrent ? Border.all(color: AppColors.red.withOpacity(0.5)) : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            qVideo.title,
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
