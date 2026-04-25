import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/pages/video_detail_page.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/domain/models/video_model.dart';
import 'package:ww/features/videos/domain/models/series_model.dart';
import 'package:ww/features/videos/presentation/pages/shorts_page.dart';
import 'package:ww/features/videos/presentation/widgets/video_thumbnail_widget.dart';
import 'package:ww/features/videos/presentation/widgets/math_gate_dialog.dart';
import 'package:ww/features/videos/presentation/pages/parental_settings_page.dart';
import 'series_detail_page.dart';

class SeriesCard extends StatelessWidget {
  final SeriesModel series;

  const SeriesCard({Key? key, required this.series}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeriesDetailPage(series: series),
          ),
        );
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[300]),
                child: (series.episodes.isNotEmpty)
                    ? VideoThumbnailWidget(
                        videoPath: series.episodes.first.videoPath,
                      )
                    : const Icon(Icons.video_collection, size: 50),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${series.episodes.length} Videos',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
                  child: Icon(Icons.playlist_play, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Series • ${series.episodes.length} items',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final isSearchVisibleProvider = StateProvider<bool>((ref) => false);

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(latestVideosProvider);
    final isSearchVisible = ref.watch(isSearchVisibleProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: isSearchVisible
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search videos...',
                  border: InputBorder.none,
                ),
                onChanged: (val) =>
                    ref.read(searchQueryProvider.notifier).state = val,
              )
            : Row(
                children: [
                  Image.asset('assets/icon.png', height: 32),
                  const SizedBox(width: 8),
                  const Text(
                    'يوتيوب جوري',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              ref.read(isSearchVisibleProvider.notifier).state =
                  !isSearchVisible;
              if (isSearchVisible) {
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
          ),
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
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
          const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: videosAsync.when(
        data: (videos) {
          final query = searchQuery.toLowerCase();
          final filtered = videos
              .where((v) => v.title.toLowerCase().contains(query))
              .toList();

          final shortsOnly = filtered.where((v) => v.type == 'short').toList();
          final normalsOnly = filtered.where((v) => v.type != 'short').toList();

          List<dynamic> feedItems = [];
          
          int shortIndex = 0;
          int normalIndex = 0;
          
          while (shortIndex < shortsOnly.length || normalIndex < normalsOnly.length) {
            // Add a shelf of shorts (up to 4)
            if (shortIndex < shortsOnly.length) {
              int end = (shortIndex + 4 < shortsOnly.length) ? shortIndex + 4 : shortsOnly.length;
              feedItems.add(shortsOnly.sublist(shortIndex, end));
              shortIndex = end;
            }

            // Add block of normal videos (e.g., 2 videos)
            for (int i = 0; i < 2; i++) {
              if (normalIndex < normalsOnly.length) {
                feedItems.add(normalsOnly[normalIndex]);
                normalIndex++;
              }
            }
          }

          return ListView.builder(
            itemCount: feedItems.length,
            itemBuilder: (context, index) {
              final item = feedItems[index];
              if (item is List<VideoModel>) {
                return ShortsGridWidget(shorts: item);
              } else {
                return VideoCard(video: item);
              }
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, s) => Center(child: Text('Error loading videos: $e')),
      ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final VideoModel video;

  const VideoCard({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoDetailPage(video: video),
          ),
        );
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[300]),
                child: VideoThumbnailWidget(videoPath: video.videoPath),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  video.duration,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${video.uploader} • ${video.views} • ${video.uploadDate}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final isFav = ref
                        .watch(favoritesProvider)
                        .contains(video.id);
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : null,
                        size: 20,
                      ),
                      onPressed: () => ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(video.id),
                    );
                  },
                ),
                const Icon(Icons.more_vert, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShortsGridWidget extends StatelessWidget {
  final List<VideoModel> shorts;

  const ShortsGridWidget({Key? key, required this.shorts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.amp_stories, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Shorts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: shorts.length,
          itemBuilder: (context, index) {
            return ShortCard(video: shorts[index]);
          },
        ),
        const SizedBox(height: 16),
        const Divider(height: 6, thickness: 4, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ShortCard extends StatelessWidget {
  final VideoModel video;

  const ShortCard({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ShortsPage()),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: VideoThumbnailWidget(videoPath: video.videoPath, fit: BoxFit.cover),
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
              video.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Positioned(
            top: 8,
            right: 8,
            child: Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
