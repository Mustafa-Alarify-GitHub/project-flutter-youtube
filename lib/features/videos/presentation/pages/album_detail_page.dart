import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:ww/features/videos/presentation/pages/photo_viewer_page.dart';
import 'package:ww/features/videos/presentation/pages/video_detail_page.dart';

class AlbumDetailPage extends StatefulWidget {
  final AssetPathEntity album;

  const AlbumDetailPage({super.key, required this.album});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  List<AssetEntity> _assets = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final int _pageSize = 80;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMoreAssets();
  }

  Future<void> _loadMoreAssets() async {
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final int assetCount = await widget.album.assetCountAsync;
    if (assetCount == 0) {
      setState(() {
        _assets = [];
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    final List<AssetEntity> newAssets = await widget.album.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    // Include both images and videos
    final List<AssetEntity> mediaAssets = newAssets.where((asset) {
      return asset.type == AssetType.image || asset.type == AssetType.video;
    }).toList();

    setState(() {
      _assets.addAll(mediaAssets);
      _currentPage++;
      _hasMore = _assets.length < assetCount && newAssets.length == _pageSize;
      _isLoading = false;
    });
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.album.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _assets.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _assets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد صور أو فيديوهات في هذا الألبوم',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 && !_isLoading) {
                      _loadMoreAssets();
                    }
                    return true;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _assets.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _assets.length) {
                        return const Center(child: CircularProgressIndicator(color: Colors.red));
                      }

                      final asset = _assets[index];
                      final isVideo = asset.type == AssetType.video;

                      return GestureDetector(
                        onTap: () {
                          if (isVideo) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoDetailPage(
                                  videoAsset: asset,
                                  albumAssets: _assets,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhotoViewerPage(
                                  assets: _assets,
                                  initialIndex: index,
                                  albumName: widget.album.name,
                                ),
                              ),
                            );
                          }
                        },
                        child: Hero(
                          tag: 'photo_${asset.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: isDark ? Colors.grey[900] : Colors.grey[200],
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  AssetEntityImage(
                                    asset,
                                    isOriginal: false,
                                    thumbnailSize: const ThumbnailSize(300, 300),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.broken_image, color: Colors.grey),
                                      );
                                    },
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: isDark ? Colors.grey[900] : Colors.grey[200],
                                      );
                                    },
                                  ),
                                  if (isVideo) ...[
                                    Container(
                                      color: Colors.black26,
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.75),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _formatDuration(asset.duration),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
