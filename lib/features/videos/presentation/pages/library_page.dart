import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/pages/home_page.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteVideosAsync = ref.watch(favoriteVideosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Recent Favorites',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
