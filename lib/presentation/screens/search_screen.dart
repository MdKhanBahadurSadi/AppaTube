import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../providers/player_provider.dart';
import '../providers/search_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/video_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final bool isSubPage;
  const SearchScreen({super.key, this.isSubPage = false});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  Timer? _debounce;
  bool _showBackButton = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();

    // Auto-focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      setState(() => _showBackButton = true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        ref.read(searchProvider.notifier).search(query);
      } else {
        ref.read(searchProvider.notifier).clearResults();
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final playerState = ref.watch(playerProvider);
    final history = ref.read(historyProvider.notifier);

    Widget content = SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              // Custom top section (AppBar replacement)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (!widget.isSubPage)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _showBackButton ? 1.0 : 0.0,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: _onSearchChanged,
                        onSubmitted: (query) {
                          _debounce?.cancel();
                          ref.read(searchProvider.notifier).search(query);
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search AppaTube...',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.red),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(searchProvider.notifier).clearResults();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surfaceHigh,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildContent(searchState, history, playerState),
                ),
              ),
            ],
          ),

          if (!widget.isSubPage && playerState.currentVideo != null)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
        ],
      ),
    );

    if (widget.isSubPage) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: content,
    );
  }

  Widget _buildContent(SearchState state, HistoryNotifier historyNotifier, PlayerState playerState) {
    if (state.query.isEmpty && !state.isLoading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trending',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['Lofi', 'Trending', 'Music', 'Podcast', 'News', 'Gaming'].map((tag) {
                return ActionChip(
                  label: Text(tag),
                  backgroundColor: AppColors.background,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.red, width: 1),
                  ),
                  onPressed: () {
                    _searchController.text = tag;
                    ref.read(searchProvider.notifier).search(tag);
                    _focusNode.unfocus();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    if (state.isLoading) {
      return _buildShimmerLoading();
    }

    if (state.results.isEmpty && state.query.isNotEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No results for "${state.query}"',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      key: ValueKey('results_${state.query}'),
      itemCount: state.results.length,
      padding: EdgeInsets.fromLTRB(0, 8, 0, widget.isSubPage ? 180 : 100),
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final video = state.results[index];
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: FutureBuilder(
            future: Future.delayed(Duration(milliseconds: index * 50)),
            builder: (context, snapshot) {
              return VideoCard(
                video: video,
                isPlaying: playerState.currentVideo?.id == video.id,
                onTap: () {
                  ref.read(playerProvider.notifier).playVideoFromList(video, state.results);
                  ref.read(historyProvider.notifier).addToHistory(video);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      key: const ValueKey('loading'),
      itemCount: 6,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: double.infinity, height: 14, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 150, height: 12, color: Colors.white),
                    ],
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
