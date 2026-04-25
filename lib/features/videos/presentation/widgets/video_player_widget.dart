import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class YouTubeVideoPlayer extends StatefulWidget {
  final String videoPath;
  final bool isShort;

  const YouTubeVideoPlayer({
    Key? key,
    required this.videoPath,
    this.isShort = false,
  }) : super(key: key);

  @override
  State<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Determine if it's an asset or a file path
    if (widget.videoPath.startsWith('assets/')) {
      _videoPlayerController = VideoPlayerController.asset(widget.videoPath);
    } else {
      _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
    }

    await _videoPlayerController.initialize();

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
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }
  }
}
