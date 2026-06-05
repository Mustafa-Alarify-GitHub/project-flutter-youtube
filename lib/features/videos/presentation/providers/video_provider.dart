import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

// SharedPreferences provider (overridden in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Photo permission provider
final photoPermissionProvider = StateNotifierProvider<PhotoPermissionNotifier, PermissionState>((ref) {
  return PhotoPermissionNotifier();
});

class PhotoPermissionNotifier extends StateNotifier<PermissionState> {
  PhotoPermissionNotifier() : super(PermissionState.notDetermined) {
    checkPermission();
  }

  Future<void> checkPermission() async {
    final state = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: false,
        ),
      ),
    );
    this.state = state;
  }

  Future<PermissionState> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: false,
        ),
      ),
    );
    this.state = state;
    return state;
  }
}

// Shorts folder name provider
final shortsFolderNameProvider = StateNotifierProvider<ShortsFolderNameNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ShortsFolderNameNotifier(prefs);
});

class ShortsFolderNameNotifier extends StateNotifier<String> {
  final SharedPreferences prefs;
  static const _key = 'shorts_folder_name';
  ShortsFolderNameNotifier(this.prefs) : super(prefs.getString(_key) ?? 'Shorts');

  void updateName(String name) {
    state = name;
    prefs.setString(_key, name);
  }
}

// Hidden albums provider
final hiddenAlbumsProvider = StateNotifierProvider<HiddenAlbumsNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HiddenAlbumsNotifier(prefs);
});

class HiddenAlbumsNotifier extends StateNotifier<List<String>> {
  final SharedPreferences prefs;
  static const _key = 'hidden_albums';
  HiddenAlbumsNotifier(this.prefs) : super(prefs.getStringList(_key) ?? []);

  void toggleAlbumVisibility(String albumId) {
    if (state.contains(albumId)) {
      state = state.where((id) => id != albumId).toList();
    } else {
      state = [...state, albumId];
    }
    prefs.setStringList(_key, state);
  }

  bool isHidden(String albumId) => state.contains(albumId);
}

// All albums provider (retrieves all paths)
final allAlbumsProvider = FutureProvider<List<AssetPathEntity>>((ref) async {
  final permission = ref.watch(photoPermissionProvider);
  if (!permission.isAuth) {
    return [];
  }
  return await PhotoManager.getAssetPathList(
    type: RequestType.common, // load images and videos
    hasAll: true,
  );
});

// Visible albums provider (filters out hidden albums and shorts folder)
final visibleAlbumsProvider = Provider<AsyncValue<List<AssetPathEntity>>>((ref) {
  final allAlbumsAsync = ref.watch(allAlbumsProvider);
  final hiddenAlbums = ref.watch(hiddenAlbumsProvider);
  final shortsFolderName = ref.watch(shortsFolderNameProvider).trim().toLowerCase();

  return allAlbumsAsync.whenData((albums) {
    return albums.where((album) {
      if (hiddenAlbums.contains(album.id)) return false;
      if (album.name.trim().toLowerCase() == shortsFolderName) return false;
      return true;
    }).toList();
  });
});

// Shorts videos provider (gets video assets from the designated shorts folder name)
final shortsVideosProvider = FutureProvider<List<AssetEntity>>((ref) async {
  final permission = ref.watch(photoPermissionProvider);
  if (!permission.isAuth) return [];

  final allAlbums = await ref.read(allAlbumsProvider.future);
  final shortsFolderName = ref.watch(shortsFolderNameProvider).trim().toLowerCase();

  try {
    final shortsAlbum = allAlbums.firstWhere(
      (album) => album.name.trim().toLowerCase() == shortsFolderName,
    );
    final List<AssetEntity> assets = await shortsAlbum.getAssetListRange(
      start: 0,
      end: await shortsAlbum.assetCountAsync,
    );
    // Filter only video types
    return assets.where((asset) => asset.type == AssetType.video).toList();
  } catch (e) {
    // If not found or empty
    return [];
  }
});

// Favorites logic
class FavoritesNotifier extends StateNotifier<List<String>> {
  final SharedPreferences prefs;
  static const _key = 'favorite_media_assets';

  FavoritesNotifier(this.prefs) : super(prefs.getStringList(_key) ?? []);

  void toggleFavorite(String assetId) {
    if (state.contains(assetId)) {
      state = state.where((id) => id != assetId).toList();
    } else {
      state = [...state, assetId];
    }
    prefs.setStringList(_key, state);
  }

  bool isFavorite(String assetId) => state.contains(assetId);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesNotifier(prefs);
});

// Load actual AssetEntity objects for favorited items
final favoriteMediaProvider = FutureProvider<List<AssetEntity>>((ref) async {
  final favoriteIds = ref.watch(favoritesProvider);
  if (favoriteIds.isEmpty) return [];

  List<AssetEntity> assets = [];
  for (final id in favoriteIds) {
    try {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        assets.add(asset);
      }
    } catch (e) {
      // Ignored if asset not found
    }
  }
  return assets;
});

// Recently Watched History logic
class HistoryNotifier extends StateNotifier<List<String>> {
  final SharedPreferences prefs;
  static const _key = 'history_media_assets';

  HistoryNotifier(this.prefs) : super(prefs.getStringList(_key) ?? []);

  void recordWatch(String assetId) {
    if (state.isNotEmpty && state.first == assetId) return; // already at top
    final newList = state.where((id) => id != assetId).toList();
    newList.insert(0, assetId);
    if (newList.length > 50) newList.removeLast(); // Keep last 50
    state = newList;
    prefs.setStringList(_key, state);
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HistoryNotifier(prefs);
});

// Load actual AssetEntity objects for history items
final historyMediaProvider = FutureProvider<List<AssetEntity>>((ref) async {
  final historyIds = ref.watch(historyProvider);
  if (historyIds.isEmpty) return [];

  List<AssetEntity> assets = [];
  for (final id in historyIds) {
    try {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        assets.add(asset);
      }
    } catch (e) {
      // Ignored if asset not found
    }
  }
  return assets;
});
