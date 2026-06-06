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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return PlaylistListCard(album: album, isDark: isDark);
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

class PlaylistListCard extends StatefulWidget {
  final AssetPathEntity album;
  final bool isDark;

  const PlaylistListCard({super.key, required this.album, required this.isDark});

  @override
  State<PlaylistListCard> createState() => _PlaylistListCardState();
}

class _PlaylistListCardState extends State<PlaylistListCard> {
  AssetEntity? _coverAsset;
  int _count = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  @override
  void didUpdateWidget(covariant PlaylistListCard oldWidget) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlbumDetailPage(album: widget.album),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: YouTube playlist thumbnail style
            SizedBox(
              width: 150,
              height: 85,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video thumbnail cover
                      _isLoading
                          ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)))
                          : _coverAsset != null
                              ? AssetEntityImage(
                                  _coverAsset!,
                                  isOriginal: false,
                                  thumbnailSize: const ThumbnailSize(300, 200),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(child: Icon(Icons.video_library, color: Colors.grey)),
                                )
                              : const Center(child: Icon(Icons.video_library, color: Colors.grey)),
                      
                      // Playlist vertical overlay on the right (like YouTube)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Icon(
                                Icons.playlist_play,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Right side: Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.album.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_count مقطع فيديو • قائمة تشغيل',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Options icon
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
