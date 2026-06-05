import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:ww/features/videos/presentation/pages/album_detail_page.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/widgets/math_gate_dialog.dart';
import 'package:ww/features/videos/presentation/pages/parental_settings_page.dart';

final isSearchVisibleProvider = StateProvider<bool>((ref) => false);
final albumSearchQueryProvider = StateProvider<String>((ref) => '');

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(photoPermissionProvider);
    final albumsAsync = ref.watch(visibleAlbumsProvider);
    final isSearchVisible = ref.watch(isSearchVisibleProvider);
    final searchQuery = ref.watch(albumSearchQueryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: isSearchVisible
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'البحث عن ألبوم...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => ref.read(albumSearchQueryProvider.notifier).state = val,
              )
            : Row(
                children: [
                  Image.asset('assets/icon.png', height: 32),
                  const SizedBox(width: 8),
                  const Text(
                    'ألبومات جوري',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              ref.read(isSearchVisibleProvider.notifier).state = !isSearchVisible;
              if (isSearchVisible) {
                ref.read(albumSearchQueryProvider.notifier).state = '';
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () async {
              final success = await MathGateDialog.show(context);
              if (success) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ParentalSettingsPage()),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, ref, permissionState, albumsAsync, searchQuery, isDark),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PermissionState permissionState,
    AsyncValue<List<AssetPathEntity>> albumsAsync,
    String searchQuery,
    bool isDark,
  ) {
    if (!permissionState.isAuth) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined, size: 80, color: Colors.red),
              ),
              const SizedBox(height: 24),
              const Text(
                'عرض صور طفلك بأمان',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'نحتاج للوصول إلى ألبوم الصور في جهازك لعرض الألبومات والصور المحددة لطفلك.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: () {
                  ref.read(photoPermissionProvider.notifier).requestPermission();
                },
                child: const Text(
                  'إعطاء الصلاحية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return albumsAsync.when(
      data: (albums) {
        final query = searchQuery.trim().toLowerCase();
        final filteredAlbums = albums.where((album) {
          return album.name.toLowerCase().contains(query);
        }).toList();

        if (filteredAlbums.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  query.isEmpty ? 'لا توجد ألبومات معروضة' : 'لم يتم العثور على ألبومات تطابق بحثك',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemCount: filteredAlbums.length,
          itemBuilder: (context, index) {
            final album = filteredAlbums[index];
            return AlbumGridCard(album: album, isDark: isDark);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (err, stack) => Center(
        child: Text(
          'خطأ في تحميل الألبومات: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

class AlbumGridCard extends StatefulWidget {
  final AssetPathEntity album;
  final bool isDark;

  const AlbumGridCard({Key? key, required this.album, required this.isDark}) : super(key: key);

  @override
  State<AlbumGridCard> createState() => _AlbumGridCardState();
}

class _AlbumGridCardState extends State<AlbumGridCard> {
  AssetEntity? _coverAsset;
  int _count = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  @override
  void didUpdateWidget(covariant AlbumGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.album.id != widget.album.id) {
      _loadCover();
    }
  }

  Future<void> _loadCover() async {
    try {
      final count = await widget.album.assetCountAsync;
      if (count > 0) {
        final List<AssetEntity> assets = await widget.album.getAssetListRange(start: 0, end: 1);
        if (assets.isNotEmpty) {
          if (mounted) {
            setState(() {
              _coverAsset = assets.first;
              _count = count;
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      // Ignored
    }
    if (mounted) {
      setState(() {
        _coverAsset = null;
        _count = 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailPage(album: widget.album),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.4 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: widget.isDark ? Colors.grey[900] : Colors.grey[200],
                  child: _isLoading
                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)))
                      : _coverAsset != null
                          ? AssetEntityImage(
                              _coverAsset!,
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize(300, 300),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey));
                              },
                            )
                          : const Center(
                              child: Icon(Icons.photo_album_outlined, size: 48, color: Colors.grey),
                            ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 10, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.album.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_count عنصر',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
