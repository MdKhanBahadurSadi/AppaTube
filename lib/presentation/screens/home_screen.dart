import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../app/routes.dart';
import '../providers/player_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/video_card.dart';
import '../widgets/animated_bottom_nav.dart';
import 'search_screen.dart';
import 'history_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              const _HomeView(),
              const SearchScreen(isSubPage: true),
              const HistoryScreen(isSubPage: true),
            ],
          ),
          
          // Mini player and Bottom Nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (playerState.currentVideo != null)
                  const MiniPlayer(),
                AnimatedBottomNav(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() => _currentIndex = index);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeView extends ConsumerWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final playerState = ref.watch(playerProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          snap: true,
          backgroundColor: AppColors.background,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            title: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(
                    text: 'Appa',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'Tube',
                    style: TextStyle(color: AppColors.red),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.cast, color: Colors.white),
              onPressed: () {},
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16, left: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceHigh,
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, Routes.search),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textMuted),
                    SizedBox(width: 12),
                    Text(
                      'Search songs, videos...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (history.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    'Continue Watching',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: history.take(5).length,
                    itemBuilder: (context, index) {
                      final video = history[index];
                      return SizedBox(
                        width: 280,
                        child: VideoCard(
                          video: video,
                          heroContext: 'continue_$index',
                          onTap: () {
                            ref.read(playerProvider.notifier).playVideoFromList(video, history);
                            ref.read(historyProvider.notifier).addToHistory(video);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recently Played',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (history.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No recently played videos',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final video = history[index];
                return VideoCard(
                  video: video,
                  heroContext: 'recent_$index',
                  isPlaying: playerState.currentVideo?.id == video.id,
                  onTap: () {
                    ref.read(playerProvider.notifier).playVideoFromList(video, history);
                    ref.read(historyProvider.notifier).addToHistory(video);
                  },
                );
              },
              childCount: history.length,
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 180), // Extra space for miniplayer + nav
        ),
      ],
    );
  }
}
