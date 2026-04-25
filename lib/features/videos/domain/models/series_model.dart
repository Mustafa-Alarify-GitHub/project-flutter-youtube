import 'package:ww/features/videos/domain/models/video_model.dart';

class SeriesModel {
  final String id;
  final String title;
  final String thumbnailPath;
  final List<VideoModel> episodes;

  SeriesModel({
    required this.id,
    required this.title,
    required this.thumbnailPath,
    required this.episodes,
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    return SeriesModel(
      id: json['id'],
      title: json['title'],
      thumbnailPath: json['thumbnail_path'],
      episodes: (json['episodes'] as List)
          .map((v) => VideoModel.fromJson({...v, 'type': 'long'}))
          .toList(),
    );
  }
}
