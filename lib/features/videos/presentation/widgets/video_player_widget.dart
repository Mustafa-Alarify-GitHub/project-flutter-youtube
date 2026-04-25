import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';

class YouTubeVideoPlayer extends ConsumerStatefulWidget {
  final String videoId;
  final String videoPath;
  final bool isShort;

  const YouTubeVideoPlayer({
    Key? key,
    required this.videoId,
    required this.videoPath,
    this.isShort = false,
  }) : super(key: key);

  @override
  ConsumerState<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends ConsumerState<YouTubeVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    // Record watch history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).recordWatch(widget.videoId);
    });
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.videoPath.startsWith('assets/')) {
      _videoPlayerController = VideoPlayerController.asset(widget.videoPath);
    } else {
      _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
    }

    await _videoPlayerController.initialize();

    // Restore saved position
    final prefs = await SharedPreferences.getInstance();
    final savedPos = prefs.getInt('pos_${widget.videoId}');
    if (savedPos != null) {
      await _videoPlayerController.seekTo(Duration(milliseconds: savedPos));
    }

    // Add listener to periodically save state
    _videoPlayerController.addListener(() {
      if (_videoPlayerController.value.isPlaying) {
        prefs.setInt('pos_${widget.videoId}', _videoPlayerController.value.position.inMilliseconds);
      }
    });

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: widget.isShort,
      aspectRatio: widget.isShort ? 9 / 16 : _videoPlayerController.value.aspectRatio,
      showControls: !widget.isShort,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.red,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white,
      ),
      autoInitialize: true,
    );
    setState(() {});
  }

  @override
  void dispose() {
    // Save state on exact dispose
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('pos_${widget.videoId}', _videoPlayerController.value.position.inMilliseconds);
    });

    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }


  void _seekRelative(Duration delta) {
    if (_videoPlayerController.value.isInitialized) {
      final currentPosition = _videoPlayerController.value.position;
      final newPosition = currentPosition + delta;
      
      if (newPosition < Duration.zero) {
        _videoPlayerController.seekTo(Duration.zero);
      } else if (newPosition > _videoPlayerController.value.duration) {
        _videoPlayerController.seekTo(_videoPlayerController.value.duration);
      } else {
        _videoPlayerController.seekTo(newPosition);
      }
    }
  }

  void _seekDrag(double dx) {
    _seekRelative(Duration(milliseconds: (dx * 200).toInt()));
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return Stack(
        children: [
          Chewie(controller: _chewieController!),
          
          if (!widget.isShort) // Shorts already have swipe logic
            Positioned(
              top: 0,
              bottom: 60, // leave space for bottom controls
              left: 0,
              right: 0,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () => _seekRelative(const Duration(seconds: -10)),
                      onHorizontalDragUpdate: (details) => _seekDrag(details.delta.dx),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () => _seekRelative(const Duration(seconds: 10)),
                      onHorizontalDragUpdate: (details) => _seekDrag(details.delta.dx),
                    ),
                  ),
                ],
              ),
            ),
          
          if (widget.isShort && _videoPlayerController.value.isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _videoPlayerController,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  backgroundColor: Colors.white24,
                  bufferedColor: Colors.white60,
                ),
              ),
            ),
        ],
      );

    } else {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }
  }
}
