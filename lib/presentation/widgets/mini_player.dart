import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miniplayer/miniplayer.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final video = playerState.currentVideo;

    if (video == null) return const SizedBox.shrink();

    final double height = MediaQuery.of(context).size.height;

    return Miniplayer(
      minHeight: 70,
      maxHeight: height,
      builder: (miniHeight, percentage) {
        if (percentage > 0.2) {
          return const PlayerScreen();
        }

        // BUG-14 fix: Use milliseconds for smoother progress
        final positionMs = playerState.position.inMilliseconds;
        final durationMs = playerState.duration.inMilliseconds;
        final progress = durationMs > 0 ? positionMs / durationMs : 0.0;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.red),
                minHeight: 2,
              ),
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 12),
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
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            video.channelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(playerState.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow),
                      onPressed: () => playerNotifier.togglePlayPause(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        // BUG-06 fix: Properly stop audio AND reset state
                        playerNotifier.stopAndReset();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
