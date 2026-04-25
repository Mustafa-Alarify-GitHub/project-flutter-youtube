import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';

class ThumbnailHelper {
  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List?> getThumbnail(String videoPath) async {
    if (_cache.containsKey(videoPath)) return _cache[videoPath];

    try {
      String pathForThumbnail = videoPath;

      if (videoPath.startsWith('assets/')) {
        final byteData = await rootBundle.load(videoPath);
        final tempDir = await getTemporaryDirectory();
        // Create a safe, unique filename based on the asset path
        final fileName = videoPath.replaceAll('/', '_');
        final file = File('${tempDir.path}/$fileName');

        if (!await file.exists()) {
          // Write the asset bytes to the temporary file
          await file.writeAsBytes(
            byteData.buffer.asUint8List(
              byteData.offsetInBytes,
              byteData.lengthInBytes,
            ),
          );
        }
        pathForThumbnail = file.path;
      }

      final uint8list = await VideoThumbnail.thumbnailData(
        video: pathForThumbnail,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320,
        quality: 50,
      );

      _cache[videoPath] = uint8list;
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
