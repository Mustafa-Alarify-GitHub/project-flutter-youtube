import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/data/data_sources/video_local_datasource.dart';

import 'package:ww/features/videos/domain/models/video_model.dart';
import 'package:ww/features/videos/domain/models/series_model.dart';

final videoDataSourceProvider = Provider((ref) => VideoLocalDataSource());

// Generic videos provider (loads shorts by default for compatibility)
final videosProvider = FutureProvider<List<VideoModel>>((ref) async {
  final dataSource = ref.watch(videoDataSourceProvider);
  return dataSource.loadShorts();
});

// Series provider
final seriesProvider = FutureProvider<List<SeriesModel>>((ref) async {
  final dataSource = ref.watch(videoDataSourceProvider);
  return dataSource.loadSeries();
});

// Shorts provider
final shortVideosProvider = FutureProvider<List<VideoModel>>((ref) async {
  final dataSource = ref.watch(videoDataSourceProvider);
  return dataSource.loadShorts();
});

// Random videos provider (for Home Feed)
final randomVideosProvider = Provider<AsyncValue<List<VideoModel>>>((ref) {
  final seriesAsync = ref.watch(seriesProvider);
  final shortVideosAsync = ref.watch(shortVideosProvider);

  return seriesAsync.whenData((series) {
    List<VideoModel> allVideos = series.expand((s) => s.episodes).toList();
    if (shortVideosAsync.hasValue) {
      allVideos.addAll(shortVideosAsync.value!);
    }
    allVideos.shuffle();
    return allVideos;
  });
});

// Search Query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Series based on search
final filteredSeriesProvider = Provider<AsyncValue<List<SeriesModel>>>((ref) {
  final allSeriesAsync = ref.watch(seriesProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return allSeriesAsync.whenData((series) {
    if (query.isEmpty) return series;
    return series.where((s) => s.title.toLowerCase().contains(query)).toList();
  });
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Favorites (Library) logic
class FavoritesNotifier extends StateNotifier<List<String>> {
  final SharedPreferences prefs;
  static const _key = 'favorite_videos';

  FavoritesNotifier(this.prefs) : super(prefs.getStringList(_key) ?? []);

  void toggleFavorite(String videoId) {
    if (state.contains(videoId)) {
      state = state.where((id) => id != videoId).toList();
    } else {
      state = [...state, videoId];
    }
    prefs.setStringList(_key, state);
  }

  bool isFavorite(String videoId) => state.contains(videoId);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesNotifier(prefs);
});

final favoriteVideosProvider = Provider<AsyncValue<List<VideoModel>>>((ref) {
  final seriesAsync = ref.watch(seriesProvider);
  final shortVideosAsync = ref.watch(shortVideosProvider);
  final favoriteIds = ref.watch(favoritesProvider);

  // We combine videos from series and shorts to search for favorites
  return seriesAsync.whenData((seriesList) {
    List<VideoModel> allVideos = seriesList.expand((s) => s.episodes).toList();
    
    // Also include shorts if they are loaded
    if (shortVideosAsync.hasValue) {
      allVideos.addAll(shortVideosAsync.value!);
    }

    return allVideos.where((v) => favoriteIds.contains(v.id)).toList();
  });
});

// Recently Watched History logic
class HistoryNotifier extends StateNotifier<List<String>> {
  final SharedPreferences prefs;
  static const _key = 'history_videos';

  HistoryNotifier(this.prefs) : super(prefs.getStringList(_key) ?? []);

  void recordWatch(String videoId) {
    if (state.isNotEmpty && state.first == videoId) return; // already at top
    final newList = state.where((id) => id != videoId).toList();
    newList.insert(0, videoId);
    if (newList.length > 50) newList.removeLast(); // Keep last 50
    state = newList;
    prefs.setStringList(_key, state);
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HistoryNotifier(prefs);
});

final historyVideosProvider = Provider<AsyncValue<List<VideoModel>>>((ref) {
  final seriesAsync = ref.watch(seriesProvider);
  final shortVideosAsync = ref.watch(shortVideosProvider);
  final historyIds = ref.watch(historyProvider);

  return seriesAsync.whenData((seriesList) {
    List<VideoModel> allVideos = seriesList.expand((s) => s.episodes).toList();
    if (shortVideosAsync.hasValue) {
      allVideos.addAll(shortVideosAsync.value!);
    }

    // Map history IDs back to VideoModels, keeping the history order
    List<VideoModel> result = [];
    for (String id in historyIds) {
      try {
        result.add(allVideos.firstWhere((v) => v.id == id));
      } catch (e) {
        // Video might have been deleted from local files
      }
    }
    return result;
  });
});
