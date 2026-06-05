import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/widgets/video_player_widget.dart';

class ShortsPage extends ConsumerWidget {
  const ShortsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsAsync = ref.watch(shortsVideosProvider);
    final shortsFolderName = ref.watch(shortsFolderNameProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: shortsAsync.when(
        data: (assets) {
          if (assets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_circle_outline_outlined, size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'لا توجد مقاطع شورت',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'الرجاء إضافة مقاطع فيديو إلى مجلد باسم [$shortsFolderName] على جهازك ليقوم التطبيق بعرضها هنا كأقسام شورت.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              final videoIndex = index % assets.length;
              return ShortVideoItem(asset: assets[videoIndex]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, s) => Center(
          child: Text(
            'حدث خطأ أثناء تحميل الفيديوهات: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class ShortVideoItem extends ConsumerWidget {
  final AssetEntity asset;

  const ShortVideoItem({Key? key, required this.asset}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<File?>(
      future: asset.file,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final file = snapshot.data;
        if (file == null) {
          return const Center(
            child: Text(
              'تعذر تحميل ملف الفيديو',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final favorites = ref.watch(favoritesProvider);
        final isFav = favorites.contains(asset.id);

        final title = asset.title?.isNotEmpty == true ? asset.title! : 'مقطع شورت';

        return YouTubeVideoPlayer(
          videoId: asset.id,
          videoPath: file.path,
          isShort: true,
          overlay: Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 30),
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
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.person, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'طفلي العزيز',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                child: const Text('قناتي', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _buildShortAction(
                          isFav ? Icons.thumb_up : Icons.thumb_up_outlined,
                          'أعجبني',
                          color: isFav ? Colors.blue : Colors.white,
                          onTap: () {
                            ref.read(favoritesProvider.notifier).toggleFavorite(asset.id);
                          },
                        ),
                        _buildShortAction(Icons.thumb_down_outlined, 'لم يعجبني'),
                        _buildShortAction(Icons.comment_outlined, 'تعليق'),
                        _buildShortAction(Icons.share_outlined, 'مشاركة'),
                        _buildShortAction(Icons.loop, 'إعادة'),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.music_note, color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
