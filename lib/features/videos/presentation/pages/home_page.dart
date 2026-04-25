import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/pages/video_detail_page.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/domain/models/video_model.dart';
import 'package:ww/features/videos/domain/models/series_model.dart';
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
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                ),
                child: series.thumbnailPath.startsWith('assets/')
                    ? Image.asset(series.thumbnailPath, fit: BoxFit.cover)
                    : (File(series.thumbnailPath).existsSync()
                        ? Image.file(File(series.thumbnailPath), fit: BoxFit.cover)
                        : const Icon(Icons.video_collection, size: 50)),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    final seriesAsync = ref.watch(filteredSeriesProvider);
    final isSearchVisible = ref.watch(isSearchVisibleProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: isSearchVisible
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search series...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
              )
            : Row(
                children: [
                   const Icon(Icons.local_florist, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text(
                    'يوتيوب جوري',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -1),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              ref.read(isSearchVisibleProvider.notifier).state = !isSearchVisible;
              if (isSearchVisible) ref.read(searchQueryProvider.notifier).state = '';
            },
          ),
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: seriesAsync.when(
        data: (series) => ListView.builder(
          itemCount: series.length,
          itemBuilder: (context, index) {
            return SeriesCard(series: series[index]);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
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
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                ),
                child: video.thumbnailPath.startsWith('assets/')
                    ? Image.asset(video.thumbnailPath, fit: BoxFit.cover)
                    : (File(video.thumbnailPath).existsSync()
                        ? Image.file(File(video.thumbnailPath), fit: BoxFit.cover)
                        : const Icon(Icons.video_collection, size: 50)),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    final isFav = ref.watch(favoritesProvider).contains(video.id);
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : null,
                        size: 20,
                      ),
                      onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(video.id),
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
