import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/pages/photo_viewer_page.dart';
import 'package:ww/features/videos/presentation/pages/video_detail_page.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({Key? key}) : super(key: key);

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteMediaAsync = ref.watch(favoriteMediaProvider);
    final historyMediaAsync = ref.watch(historyMediaProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // History Section Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 12.0),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('سجل المشاهدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // History Items List
          SliverToBoxAdapter(
            child: historyMediaAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('لم يتم عرض أي وسائط مؤخراً.', style: TextStyle(color: Colors.grey)),
                  );
                }
                return SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: assets.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      final isVideo = asset.type == AssetType.video;

                      return Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            if (isVideo) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoDetailPage(
                                    videoAsset: asset,
                                    albumAssets: assets,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PhotoViewerPage(
                                    assets: assets,
                                    initialIndex: index,
                                    albumName: 'سجل المشاهدة',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
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
                                          thumbnailSize: const ThumbnailSize(200, 200),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (context, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                        if (isVideo) ...[
                                          Container(
                                            color: Colors.black26,
                                            child: const Center(
                                              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.75),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                _formatDuration(asset.duration),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
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
                              const SizedBox(height: 6),
                              Text(
                                asset.title?.isNotEmpty == true ? asset.title! : (isVideo ? 'فيديو' : 'صورة'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
              error: (e, s) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('خطأ في تحميل السجل: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: Divider(height: 40)),

          // Favorites Section Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red),
                  SizedBox(width: 8),
                  Text('المفضلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // Favorites Items Grid
          favoriteMediaAsync.when(
            data: (assets) {
              if (assets.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'لا توجد وسائط مفضلة بعد.\nاضغط على زر القلب أثناء تصفح الصور أو الفيديوهات لإضافتها هنا.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final asset = assets[index];
                      final isVideo = asset.type == AssetType.video;

                      return InkWell(
                        onTap: () {
                          if (isVideo) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoDetailPage(
                                  videoAsset: asset,
                                  albumAssets: assets,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhotoViewerPage(
                                  assets: assets,
                                  initialIndex: index,
                                  albumName: 'المفضلة',
                                ),
                              ),
                            );
                          }
                        },
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
                                  thumbnailSize: const ThumbnailSize(200, 200),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                                if (isVideo) ...[
                                  Container(
                                    color: Colors.black26,
                                    child: const Center(
                                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.75),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        _formatDuration(asset.duration),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
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
                      );
                    },
                    childCount: assets.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.red)),
            ),
            error: (e, s) => SliverFillRemaining(
              child: Center(child: Text('خطأ في تحميل المفضلة: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}
