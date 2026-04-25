import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/domain/models/video_model.dart';
import 'package:ww/features/videos/presentation/widgets/video_player_widget.dart';

class VideoDetailPage extends ConsumerWidget {
  final VideoModel video;

  const VideoDetailPage({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).contains(video.id);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YouTubeVideoPlayer(videoPath: video.videoPath),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${video.views} • ${video.uploadDate}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAction(Icons.thumb_up_outlined, 'Like'),
                      _buildAction(Icons.thumb_down_outlined, 'Dislike'),
                      _buildAction(Icons.share_outlined, 'Share'),
                      _buildAction(Icons.download_outlined, 'Download'),
                      _buildAction(
                        isFav ? Icons.library_add_check : Icons.library_add_outlined,
                        'Save',
                        color: isFav ? Colors.blue : null,
                        onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(video.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video.uploader, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text('1.2M subscribers', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('SUBSCRIBE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Mock suggested videos
                  const Text('Up Next', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Center(child: Text('No more local videos found.')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
