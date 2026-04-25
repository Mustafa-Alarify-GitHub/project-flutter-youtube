import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/widgets/video_player_widget.dart';
import 'package:ww/features/videos/domain/models/video_model.dart';

class ShortsPage extends ConsumerWidget {
  const ShortsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsAsync = ref.watch(shortVideosProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: shortsAsync.when(
        data: (videos) {
          if (videos.isEmpty) return const Center(child: Text('No shorts available', style: TextStyle(color: Colors.white)));
          return PageView.builder(
            scrollDirection: Axis.vertical,
            // Infinite scrolling logic
            itemBuilder: (context, index) {
              final videoIndex = index % videos.length;
              return ShortVideoItem(video: videos[videoIndex]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

class ShortVideoItem extends StatelessWidget {
  final VideoModel video;

  const ShortVideoItem({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return YouTubeVideoPlayer(
      videoId: video.id,
      videoPath: video.videoPath,
      isShort: true,
      overlay: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: IgnorePointer(
          ignoring: false,
          child: Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 30), // Extra bottom padding for the slider
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 16, backgroundColor: Colors.grey),
                          const SizedBox(width: 8),
                          Text(video.uploader, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                            child: const Text('SUBSCRIBE', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(video.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final isFav = ref.watch(favoritesProvider).contains(video.id);
                        return _buildShortAction(
                          isFav ? Icons.thumb_up : Icons.thumb_up_outlined,
                          'Like',
                          color: isFav ? Colors.blue : Colors.white,
                          onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(video.id),
                        );
                      },
                    ),
                    _buildShortAction(Icons.thumb_down_outlined, 'Dislike'),
                    _buildShortAction(Icons.comment_outlined, 'Comment'),
                    _buildShortAction(Icons.share_outlined, 'Share'),
                    _buildShortAction(Icons.loop, 'Remix'),
                    const CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Icon(Icons.music_note, color: Colors.black)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortAction(IconData icon, String label, {VoidCallback? onTap, Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
