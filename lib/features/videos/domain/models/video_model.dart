class VideoModel {
  final String id;
  final String title;
  final String videoPath;
  final String thumbnailPath;
  final String type; // 'long' or 'short'
  final String duration;
  final String uploader;
  final String views;
  final String uploadDate;

  VideoModel({
    required this.id,
    required this.title,
    required this.videoPath,
    required this.thumbnailPath,
    required this.type,
    required this.duration,
    required this.uploader,
    required this.views,
    required this.uploadDate,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      title: json['title'],
      videoPath: json['video_path'],
      thumbnailPath: json['thumbnail_path'],
      type: json['type'],
      duration: json['duration'] ?? '0:00',
      uploader: json['uploader'] ?? 'Unknown',
      views: json['views'] ?? '0 views',
      uploadDate: json['upload_date'] ?? 'Just now',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'video_path': videoPath,
      'thumbnail_path': thumbnailPath,
      'type': type,
      'duration': duration,
      'uploader': uploader,
      'views': views,
      'upload_date': uploadDate,
    };
  }
}
