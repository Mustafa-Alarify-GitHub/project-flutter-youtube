import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:ww/features/videos/presentation/pages/album_detail_page.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/widgets/math_gate_dialog.dart';
import 'package:ww/features/videos/presentation/pages/parental_settings_page.dart';

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(photoPermissionProvider);
    final albumsAsync = ref.watch(visibleAlbumsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'قوائم التشغيل',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
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
      body: _buildBody(context, ref, permissionState, albumsAsync, isDark),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PermissionState permissionState,
    AsyncValue<List<AssetPathEntity>> albumsAsync,
    bool isDark,
  ) {
    if (!permissionState.isAuth) {
      return const Center(child: Text('الرجاء إعطاء صلاحية الوصول في البداية'));
    }

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد مجلدات معروضة. يمكنك تفعيلها من الإعدادات.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return PlaylistGridCard(album: album, isDark: isDark);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (err, stack) => Center(
        child: Text(
          'خطأ في تحميل المجلدات: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

class PlaylistGridCard extends StatefulWidget {
  final AssetPathEntity album;
  final bool isDark;

  const PlaylistGridCard({super.key, required this.album, required this.isDark});

  @override
  State<PlaylistGridCard> createState() => _PlaylistGridCardState();
}

class _PlaylistGridCardState extends State<PlaylistGridCard> {
  AssetEntity? _coverAsset;
  int _count = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  @override
  void didUpdateWidget(covariant PlaylistGridCard oldWidget) {
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
                  '$_count مقطع فيديو',
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
