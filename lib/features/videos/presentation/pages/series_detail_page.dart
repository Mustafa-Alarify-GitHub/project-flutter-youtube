import 'package:flutter/material.dart';
import 'package:ww/features/videos/domain/models/series_model.dart';
import 'package:ww/features/videos/presentation/pages/home_page.dart';

class SeriesDetailPage extends StatelessWidget {
  final SeriesModel series;

  const SeriesDetailPage({Key? key, required this.series}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(series.title),
      ),
      body: ListView.builder(
        itemCount: series.episodes.length,
        itemBuilder: (context, index) {
          return VideoCard(video: series.episodes[index]);
        },
      ),
    );
  }
}
