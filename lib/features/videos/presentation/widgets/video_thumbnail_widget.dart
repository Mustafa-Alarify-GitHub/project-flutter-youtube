import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';

class ThumbnailHelper {
  static final Map<String, Uint8List> _memCache = {};

  static Future<Uint8List?> getThumbnail(String videoPath) async {
    if (_memCache.containsKey(videoPath)) return _memCache[videoPath];

    try {
      final tempDir = await getTemporaryDirectory();
      final thumbFileName = 'thumb_${videoPath.replaceAll('/', '_').replaceAll('.', '_')}.jpg';
      final thumbFile = File('${tempDir.path}/$thumbFileName');

      if (await thumbFile.exists()) {
        final bytes = await thumbFile.readAsBytes();
        _memCache[videoPath] = bytes;
        return bytes;
      }

      String pathForThumbnail = videoPath;
      bool isTemporaryVideo = false;

      if (videoPath.startsWith('assets/')) {
        final byteData = await rootBundle.load(videoPath);
        final videoFileName = 'temp_vid_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final tempVideoFile = File('${tempDir.path}/$videoFileName');
        
        await tempVideoFile.writeAsBytes(
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
        pathForThumbnail = tempVideoFile.path;
        isTemporaryVideo = true;
      }

      final uint8list = await VideoThumbnail.thumbnailData(
        video: pathForThumbnail,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320,
        quality: 50,
      );

      if (isTemporaryVideo) {
        final file = File(pathForThumbnail);
        if (await file.exists()) await file.delete();
      }

      if (uint8list != null) {
        await thumbFile.writeAsBytes(uint8list);
        _memCache[videoPath] = uint8list;
      }

      return uint8list;
    } catch (e) {
      debugPrint('Error generating thumbnail for $videoPath: $e');
      return null;
    }
  }
}

class VideoThumbnailWidget extends StatelessWidget {
  final String videoPath;
  final BoxFit fit;

  const VideoThumbnailWidget({
    Key? key,
    required this.videoPath,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: ThumbnailHelper.getThumbnail(videoPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.red,
              ),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
          );
        }
        // Fallback icon if thumbnail generation fails
        return const Center(
          child: Icon(Icons.video_collection, size: 50, color: Colors.grey),
        );
      },
    );
  }
}
