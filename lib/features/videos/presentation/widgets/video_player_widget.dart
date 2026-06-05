import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/providers/parental_provider.dart';

class YouTubeVideoPlayer extends ConsumerStatefulWidget {
  final String videoId;
  final String videoPath;
  final bool isShort;
  final Widget? overlay;

  const YouTubeVideoPlayer({
    super.key,
    required this.videoId,
    required this.videoPath,
    this.isShort = false,
    this.overlay,
  });

  @override
  ConsumerState<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends ConsumerState<YouTubeVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
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
    if (widget.isShort) {
      await _videoPlayerController.setLooping(true);
    }

    final prefs = await SharedPreferences.getInstance();
    if (!widget.isShort) {
      final savedPos = prefs.getInt('pos_${widget.videoId}');
      if (savedPos != null) {
        await _videoPlayerController.seekTo(Duration(milliseconds: savedPos));
      }

      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.isPlaying) {
          prefs.setInt('pos_${widget.videoId}', _videoPlayerController.value.position.inMilliseconds);
        }
      });
    }

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: widget.isShort,
      aspectRatio: widget.isShort ? 9 / 16 : _videoPlayerController.value.aspectRatio,
      showControls: !widget.isShort,
      // This overlay works in both Normal and Full Screen modes
      overlay: widget.isShort ? null : _VideoGestureLayer(controller: _videoPlayerController),
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.red,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white,
      ),
      autoInitialize: true,
    );

    // Apply parental volume limit
    final parentalState = ref.read(parentalProvider);
    _videoPlayerController.setVolume(parentalState.maxVolume);

    setState(() {});
  }

  @override
  void dispose() {
    SharedPreferences.getInstance().then((prefs) {
      if (!widget.isShort && _videoPlayerController.value.isInitialized) {
        prefs.setInt('pos_${widget.videoId}', _videoPlayerController.value.position.inMilliseconds);
      }
    });
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for volume limit changes
    ref.listen(parentalProvider.select((s) => s.maxVolume), (prev, next) {
      if (_videoPlayerController.value.isInitialized) {
        _videoPlayerController.setVolume(next);
      }
    });

    // Pause video if time is up
    ref.listen(parentalProvider, (prev, next) {
      final isTimeUp = next.dailyTimeLimitMinutes > 0 && 
                       next.consumedTimeSeconds >= (next.dailyTimeLimitMinutes * 60);
      if (isTimeUp && _videoPlayerController.value.isPlaying) {
        _videoPlayerController.pause();
      }
    });

    if (_chewieController == null || !_videoPlayerController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    return Stack(
      children: [
        Chewie(controller: _chewieController!),
        if (widget.overlay != null) widget.overlay!,
        
        if (widget.isShort)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SizedBox(
              height: 20,
              child: ValueListenableBuilder(
                valueListenable: _videoPlayerController,
                builder: (context, value, child) {
                  final max = value.duration.inMilliseconds.toDouble();
                  final pos = value.position.inMilliseconds.toDouble();
                  final safeMax = max <= 0 ? 1.0 : max;
                  return SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      activeTrackColor: Colors.red,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.red,
                    ),
                    child: Slider(
                      value: pos.clamp(0.0, safeMax),
                      min: 0.0,
                      max: safeMax,
                      onChanged: (v) => _videoPlayerController.seekTo(Duration(milliseconds: v.toInt())),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoGestureLayer extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoGestureLayer({required this.controller});

  @override
  State<_VideoGestureLayer> createState() => _VideoGestureLayerState();
}

class _VideoGestureLayerState extends State<_VideoGestureLayer> {
  Offset? _tapDownPos;

  void _seekRelative(Duration delta) {
    var newPos = widget.controller.value.position + delta;
    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > widget.controller.value.duration) newPos = widget.controller.value.duration;
    widget.controller.seekTo(newPos);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                top: 0, left: 0, right: 0, bottom: 80, // Top area for gestures
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTapDown: (d) => _tapDownPos = d.localPosition,
                  onDoubleTap: () {
                    if (_tapDownPos == null) return;
                    if (_tapDownPos!.dx < constraints.maxWidth / 2) {
                      _seekRelative(const Duration(seconds: -10));
                    } else {
                      _seekRelative(const Duration(seconds: 10));
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                     // Scrubbing: move seek based on drag distance
                     final deltaMs = (details.delta.dx * 150).toInt();
                     _seekRelative(Duration(milliseconds: deltaMs));
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
