import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';

class PhotoViewerPage extends ConsumerStatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;
  final String albumName;

  const PhotoViewerPage({
    super.key,
    required this.assets,
    required this.initialIndex,
    required this.albumName,
  });

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Record initial view in history
    _recordWatchHistory(_currentIndex);
  }

  void _recordWatchHistory(int index) {
    if (index >= 0 && index < widget.assets.length) {
      final asset = widget.assets[index];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(historyProvider.notifier).recordWatch(asset.id);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assets.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('لا توجد وسائط لعرضها', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final currentAsset = widget.assets[_currentIndex];
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(currentAsset.id);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Swiper / Interactive Viewer
          GestureDetector(
            onTap: _toggleUI,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.assets.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _recordWatchHistory(index);
              },
              itemBuilder: (context, index) {
                final asset = widget.assets[index];
                return Hero(
                  tag: 'photo_${asset.id}',
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: AssetEntityImage(
                        asset,
                        isOriginal: true, // load original high quality photo in viewer
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey, size: 60),
                          );
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top Header UI Overlay
          if (_showUI)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 24,
                  left: 16,
                  right: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.albumName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_currentIndex + 1} / ${widget.assets.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(currentAsset.id);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFav ? 'تمت الإزالة من المفضلة' : 'تمت الإضافة للمفضلة',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: isFav ? Colors.grey[800] : Colors.red,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
