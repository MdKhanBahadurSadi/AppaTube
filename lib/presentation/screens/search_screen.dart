import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../providers/search_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/video_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        ref.read(searchProvider.notifier).search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search AppaTube',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
          onSubmitted: (query) {
            _debounce?.cancel();
            ref.read(searchProvider.notifier).search(query);
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (searchState.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (searchState.error != null)
                  Expanded(
                    child:
                        Center(child: Text('Error: ${searchState.error}')),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: searchState.results.length,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (context, index) {
                        final video = searchState.results[index];
                        return VideoCard(
                          video: video,
                          onTap: () {
                            // BUG-07 fix: populate queue from search results
                            ref
                                .read(playerProvider.notifier)
                                .playVideoFromList(
                                    video, searchState.results);
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
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }
}
