import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/pages/video_detail_page.dart';
import 'package:ww/features/videos/presentation/pages/shorts_page.dart';
import 'package:ww/features/videos/presentation/widgets/math_gate_dialog.dart';
import 'package:ww/features/videos/presentation/pages/parental_settings_page.dart';

final isSearchVisibleProvider = StateProvider<bool>((ref) => false);
final feedSearchQueryProvider = StateProvider<String>((ref) => '');

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(photoPermissionProvider);
    final feedVideosAsync = ref.watch(homeFeedVideosProvider);
    final shortsAsync = ref.watch(shortsVideosProvider);
    final isSearchVisible = ref.watch(isSearchVisibleProvider);
    final searchQuery = ref.watch(feedSearchQueryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: isSearchVisible
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'البحث عن فيديوهات...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => ref.read(feedSearchQueryProvider.notifier).state = val,
              )
            : Row(
                children: [
                  Image.asset('assets/icon.png', height: 32),
                  const SizedBox(width: 8),
                  const Text(
                    'يوتيوب جوري',
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
                ref.read(feedSearchQueryProvider.notifier).state = '';
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
      body: _buildBody(context, ref, permissionState, feedVideosAsync, shortsAsync, searchQuery, isDark),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PermissionState permissionState,
    AsyncValue<List<AssetEntity>> feedVideosAsync,
    AsyncValue<List<AssetEntity>> shortsAsync,
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
              const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'يرجى إعطاء الصلاحيات اللازمة للوصول إلى الفيديوهات.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => ref.read(photoPermissionProvider.notifier).requestPermission(),
                child: const Text('إعطاء الصلاحية'),
              ),
            ],
          ),
        ),
      );
    }

    return feedVideosAsync.when(
      data: (videos) {
        final query = searchQuery.trim().toLowerCase();
        final filteredVideos = query.isEmpty
            ? videos
            : videos.where((v) {
                final title = v.title?.toLowerCase() ?? '';
                return title.contains(query);
              }).toList();

        if (filteredVideos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_collection_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  query.isEmpty ? 'لا توجد فيديوهات في المجلدات المحددة.' : 'لم يتم العثور على فيديوهات تطابق بحثك.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Mix normal videos and shorts shelf
        final shorts = shortsAsync.value ?? [];
        List<dynamic> feedItems = [];

        // Insert shorts shelf at index 2 (or at the top if there are few videos)
        if (shorts.isNotEmpty) {
          if (filteredVideos.length <= 2) {
            feedItems.add(shorts);
            feedItems.addAll(filteredVideos);
          } else {
            feedItems.addAll(filteredVideos.sublist(0, 2));
            feedItems.add(shorts);
            feedItems.addAll(filteredVideos.sublist(2));
          }
        } else {
          feedItems.addAll(filteredVideos);
        }

        return ListView.builder(
          itemCount: feedItems.length,
          itemBuilder: (context, index) {
            final item = feedItems[index];
            if (item is List<AssetEntity>) {
              return ShortsHorizontalShelf(shorts: item);
            } else {
              return VideoCard(video: item, allVideos: filteredVideos);
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'حدث خطأ أثناء تحميل الفيديوهات: $err',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final AssetEntity video;
  final List<AssetEntity> allVideos;

  const VideoCard({super.key, required this.video, required this.allVideos});

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = video.title?.isNotEmpty == true ? video.title! : 'مقطع فيديو';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoDetailPage(
              videoAsset: video,
              albumAssets: allVideos,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  child: AssetEntityImage(
                    video,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize(640, 360),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                      );
                    },
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(video.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'فيديو محلي • ${video.createDateTime.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final favorites = ref.watch(favoritesProvider);
                    final isFav = favorites.contains(video.id);
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : null,
                        size: 22,
                      ),
                      onPressed: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(video.id);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class ShortsHorizontalShelf extends StatelessWidget {
  final List<AssetEntity> shorts;

  const ShortsHorizontalShelf({super.key, required this.shorts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.bolt, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'شورتس',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shorts.length,
            itemBuilder: (context, index) {
              final video = shorts[index];
              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    // Navigate to Shorts Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShortsPage(),
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: isDark ? Colors.grey[900] : Colors.grey[200],
                          child: AssetEntityImage(
                            video,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize(250, 400),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Text(
                          video.title?.isNotEmpty == true ? video.title! : 'مقطع شورتس',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 6, thickness: 4),
        const SizedBox(height: 16),
      ],
    );
  }
}
