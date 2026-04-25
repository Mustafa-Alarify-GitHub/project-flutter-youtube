import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/pages/home_page.dart';
import 'package:ww/features/videos/presentation/pages/shorts_page.dart';
import 'package:ww/features/videos/presentation/pages/video_detail_page.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteVideosAsync = ref.watch(favoriteVideosProvider);
    final historyVideosAsync = ref.watch(historyVideosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Library', style: TextStyle(fontWeight: FontWeight.bold))),
      body: CustomScrollView(
        slivers: [
          // History Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: historyVideosAsync.when(
              data: (videos) {
                if (videos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No recently watched videos.'),
                  );
                }
                return SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: videos.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final v = videos[index];
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            if (v.type == 'short') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ShortsPage()));
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => VideoDetailPage(video: v)));
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(image: AssetImage(v.thumbnailPath), fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(v.uploader, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 32)),

          // Favorites Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.playlist_play, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Favorites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          favoriteVideosAsync.when(
            data: (videos) => videos.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: Text('No favorites yet.')),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => VideoCard(video: videos[index]),
                      childCount: videos.length,
                    ),
                  ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
