import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/video_card.dart';

class HistoryScreen extends ConsumerWidget {
  final bool isSubPage;
  const HistoryScreen({super.key, this.isSubPage = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final playerState = ref.watch(playerProvider);

    Widget content = SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: AppColors.red),
                      onPressed: () {
                        ref.read(historyProvider.notifier).clearHistory();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: AppColors.textMuted),
                            SizedBox(height: 16),
                            Text("No history yet",
                                style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: history.length,
                        padding: EdgeInsets.only(bottom: isSubPage ? 180 : 80),
                        itemBuilder: (context, index) {
                          final video = history[index];
                          return VideoCard(
                            video: video,
                            heroContext: 'history_$index',
                            isPlaying: playerState.currentVideo?.id == video.id,
                            onTap: () {
                              ref
                                  .read(playerProvider.notifier)
                                  .playVideoFromList(video, history);
                              ref
                                  .read(historyProvider.notifier)
                                  .addToHistory(video);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          if (!isSubPage && playerState.currentVideo != null)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
        ],
      ),
    );

    if (isSubPage) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: content,
    );
  }
}
