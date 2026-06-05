import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:ww/features/videos/presentation/widgets/video_player_widget.dart';
import 'package:ww/features/videos/presentation/pages/photo_viewer_page.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';

class VideoDetailPage extends ConsumerStatefulWidget {
  final AssetEntity videoAsset;
  final List<AssetEntity> albumAssets;

  const VideoDetailPage({
    Key? key,
    required this.videoAsset,
    required this.albumAssets,
  }) : super(key: key);

  @override
  ConsumerState<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends ConsumerState<VideoDetailPage> {
  late AssetEntity _currentAsset;
  File? _videoFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.videoAsset;
    _loadVideoFile();
  }

  Future<void> _loadVideoFile() async {
    setState(() {
      _isLoading = true;
      _videoFile = null;
    });

    // Record watch history
    ref.read(historyProvider.notifier).recordWatch(_currentAsset.id);

    try {
      final file = await _currentAsset.file;
      if (mounted) {
        setState(() {
          _videoFile = file;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeVideo(AssetEntity newAsset) {
    if (newAsset.id == _currentAsset.id) return;
    setState(() {
      _currentAsset = newAsset;
    });
    _loadVideoFile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Suggested assets from the same album
    final suggestedAssets = widget.albumAssets;

    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(_currentAsset.id);

    final title = _currentAsset.title?.isNotEmpty == true ? _currentAsset.title! : 'مقطع فيديو';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Player Container
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.red))
                  : _videoFile == null
                      ? const Center(child: Text('تعذر تحميل ملف الفيديو', style: TextStyle(color: Colors.white)))
                      : YouTubeVideoPlayer(
                          key: ValueKey(_currentAsset.id),
                          videoId: _currentAsset.id,
                          videoPath: _videoFile!.path,
                          isShort: false,
                        ),
            ),
          ),

          // Video Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تم الإنشاء في: ${_currentAsset.createDateTime.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : null,
                    size: 28,
                  ),
                  onPressed: () {
                    ref.read(favoritesProvider.notifier).toggleFavorite(_currentAsset.id);
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // Suggested list header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'المحتوى المقترح من هذا الألبوم',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Suggested items list
          Expanded(
            child: suggestedAssets.isEmpty
                ? const Center(child: Text('لا توجد مقاطع مقترحة أخرى'))
                : ListView.builder(
                    itemCount: suggestedAssets.length,
                    itemBuilder: (context, index) {
                      final asset = suggestedAssets[index];
                      final isCurrent = asset.id == _currentAsset.id;
                      final isVideo = asset.type == AssetType.video;
                      final itemTitle = asset.title?.isNotEmpty == true ? asset.title! : (isVideo ? 'مقطع فيديو' : 'صورة');

                      return Container(
                        color: isCurrent ? theme.colorScheme.primary.withOpacity(0.08) : null,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 80,
                              height: 45,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  AssetEntityImage(
                                    asset,
                                    isOriginal: false,
                                    thumbnailSize: const ThumbnailSize(200, 200),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, e, s) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                                  ),
                                  if (isVideo)
                                    Container(
                                      color: Colors.black26,
                                      child: const Center(
                                        child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          title: Text(
                            itemTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? theme.colorScheme.primary : null,
                            ),
                          ),
                          subtitle: Text(isVideo ? 'فيديو' : 'صورة'),
                          onTap: () {
                            if (isVideo) {
                              _changeVideo(asset);
                            } else {
                              // Open photo viewer
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PhotoViewerPage(
                                    assets: suggestedAssets,
                                    initialIndex: index,
                                    albumName: 'الألبوم',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
