import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/helpers.dart';
import '../providers/player_provider.dart';
import '../widgets/video_card.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final video = playerState.currentVideo;

    if (video == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
            child: Text("No video playing",
                style: TextStyle(color: Colors.white))),
      );
    }

    // BUG-13 fix: Clamp position to never exceed duration
    final positionSec = playerState.position.inSeconds.toDouble();
    final durationSec = playerState.duration.inSeconds.toDouble();
    final maxSlider = durationSec > 0 ? durationSec : positionSec + 1;
    final clampedPosition = min(positionSec, maxSlider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banner
              if (playerState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          'ERROR: ${playerState.error ?? "Unknown error"}',
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        onPressed: () => playerNotifier.playVideo(video),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              // Thumbnail with loading overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (playerState.isLoading)
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                video.channelName,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFFF0000),
                  inactiveTrackColor: Colors.white24,
                  thumbColor: const Color(0xFFFF0000),
                  overlayColor: const Color(0xFFFF0000).withAlpha(32),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: clampedPosition,
                  max: maxSlider,
                  onChanged: (value) {
                    final pos = Duration(seconds: value.toInt());
                    // BUG-05 fix: Use seekTo which delegates to audio handler
                    playerNotifier.seekTo(pos);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // BUG-16 fix: Use shared helper
                  Text(formatDuration(playerState.position),
                      style: const TextStyle(color: Colors.white70)),
                  Text(formatDuration(playerState.duration),
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.shuffle,
                        color: playerState.isShuffled
                            ? const Color(0xFFFF0000)
                            : Colors.white),
                    onPressed: () => playerNotifier.toggleShuffle(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.skip_previous,
                        color: Colors.white, size: 36),
                    onPressed: () => playerNotifier.playPrevious(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      playerState.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 64,
                    ),
                    onPressed: () => playerNotifier.togglePlayPause(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        color: Colors.white, size: 36),
                    onPressed: () => playerNotifier.playNext(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.repeat,
                        color: playerState.isRepeat
                            ? const Color(0xFFFF0000)
                            : Colors.white),
                    onPressed: () => playerNotifier.toggleRepeat(),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (playerState.queue.isNotEmpty) ...[
                const Text(
                  "Up Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: playerState.queue.length,
                  itemBuilder: (context, index) {
                    final nextVideo = playerState.queue[index];
                    return VideoCard(
                      video: nextVideo,
                      onTap: () => playerNotifier.playVideo(nextVideo),
                    );
                  },
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
