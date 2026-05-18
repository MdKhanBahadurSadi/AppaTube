import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../app/routes.dart';
import '../../core/constants/play_mode.dart';
import '../../core/constants/repeat_mode.dart';
import '../providers/player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final video = playerState.currentVideo;

    final bool isVisible = video != null;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1.0 : 0.0,
        child: isVisible
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (playerState.playMode == PlayMode.audio) {
                        Navigator.pushNamed(context, Routes.player);
                      } else {
                        Navigator.pushNamed(context, Routes.videoPlayer);
                      }
                    },
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity! < -200) {
                        Navigator.pushNamed(context, Routes.player);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      // Left: Thumbnail
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: video.thumbnailUrl,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Center: Title & Channel
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              video.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              video.channelName,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Right: Controls
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (playerState.repeatMode != RepeatMode.none)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Icon(
                                                playerState.repeatMode == RepeatMode.one
                                                    ? Icons.repeat_one_rounded
                                                    : Icons.repeat_rounded,
                                                color: AppColors.red,
                                                size: 14,
                                              ),
                                            ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.skip_previous_rounded,
                                              size: 22,
                                              color: Colors.white,
                                            ),
                                            onPressed: () => playerNotifier.playPrevious(),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              playerState.isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              size: 28,
                                              color: AppColors.red,
                                            ),
                                            onPressed: () => playerNotifier.togglePlayPause(),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.skip_next_rounded,
                                              size: 22,
                                              color: Colors.white,
                                            ),
                                            onPressed: () => playerNotifier.playNext(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Progress Indicator
                              LinearProgressIndicator(
                                value: playerState.duration.inSeconds > 0
                                    ? playerState.position.inSeconds /
                                        playerState.duration.inSeconds
                                    : 0.0,
                                minHeight: 2,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
