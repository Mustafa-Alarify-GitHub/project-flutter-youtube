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

// Favorites (Library) logic
class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]);

  void toggleFavorite(String videoId) {
    if (state.contains(videoId)) {
      state = state.where((id) => id != videoId).toList();
    } else {
      state = [...state, videoId];
    }
  }

  bool isFavorite(String videoId) => state.contains(videoId);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  return FavoritesNotifier();
});

final favoriteVideosProvider = Provider<AsyncValue<List<VideoModel>>>((ref) {
  final allVideosAsync = ref.watch(videosProvider);
  final favoriteIds = ref.watch(favoritesProvider);

  return allVideosAsync.whenData((videos) {
    return videos.where((v) => favoriteIds.contains(v.id)).toList();
  });
});
