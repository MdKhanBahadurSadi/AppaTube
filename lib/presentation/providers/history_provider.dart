import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/video_model.dart';

class HistoryNotifier extends Notifier<List<VideoModel>> {
  @override
  List<VideoModel> build() {
    // BUG-04 fix: Auto-load history on provider initialization
    _loadHistory();
    return [];
  }

  Future<void> _loadHistory() async {
    final box = await Hive.openBox<VideoModel>(AppConstants.hiveVideoBox);
    state = box.values.toList().reversed.toList();
  }

  Future<void> loadHistory() async {
    await _loadHistory();
  }

  Future<void> addToHistory(VideoModel video) async {
    final box = await Hive.openBox<VideoModel>(AppConstants.hiveVideoBox);

    final currentHistory = List<VideoModel>.from(state);
    currentHistory.removeWhere((v) => v.id == video.id);
    currentHistory.insert(0, video);

    if (currentHistory.length > AppConstants.maxHistoryItems) {
      state = currentHistory.sublist(0, AppConstants.maxHistoryItems);
    } else {
      state = currentHistory;
    }

    await box.clear();
    await box.addAll(state);
  }

  Future<void> clearHistory() async {
    final box = await Hive.openBox<VideoModel>(AppConstants.hiveVideoBox);
    await box.clear();
    state = [];
  }
}

final historyProvider =
    NotifierProvider<HistoryNotifier, List<VideoModel>>(HistoryNotifier.new);
