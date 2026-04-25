import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:ww/features/videos/domain/models/video_model.dart';
import 'package:ww/features/videos/domain/models/series_model.dart';

class VideoLocalDataSource {
  Future<List<VideoModel>> loadShorts() async {
    try {
      final String response = await rootBundle.loadString('assets/shorts.json');
      final List<dynamic> data = json.decode(response);
      final videos = data.map((json) => VideoModel.fromJson(json)).toList();
      videos.shuffle();
      return videos;
    } catch (e) {
      print('Error loading shorts: $e');
      return [];
    }
  }

  Future<List<SeriesModel>> loadSeries() async {
    try {
      final String response = await rootBundle.loadString('assets/series.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => SeriesModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading series: $e');
      return [];
    }
  }

  // Keeping old one for backward compatibility if needed, but we'll use specific ones now
  Future<List<VideoModel>> loadVideos() async {
    final shorts = await loadShorts();
    // For general feed we could combine or anything, but let's stick to the new structure
    return shorts; 
  }
}
