import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/youtube_service.dart';
import '../../data/models/video_model.dart';

class SearchState {
  final List<VideoModel> results;
  final bool isLoading;
  final String? error;
  final String query;

  SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  /// BUG-09 fix: Use [clearError] flag to explicitly clear [error].
  /// Without passing [error], the current value is preserved.
  /// Pass [clearError: true] to set error to null.
  SearchState copyWith({
    List<VideoModel>? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? query,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => SearchState();

  Future<void> search(String query) async {
    if (query.isEmpty) return;
    state = state.copyWith(isLoading: true, query: query, clearError: true);
    try {
      final service = ref.read(youtubeServiceProvider);
      final results = await service.searchVideos(query);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearResults() {
    state = SearchState();
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

final youtubeServiceProvider =
    Provider<YoutubeService>((ref) => YoutubeService());
