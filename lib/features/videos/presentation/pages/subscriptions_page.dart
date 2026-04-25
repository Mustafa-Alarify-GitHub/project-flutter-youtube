import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/pages/home_page.dart'; // for SeriesCard

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(filteredSeriesProvider);
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          const SizedBox(width: 12),
        ],
      ),
      body: seriesAsync.when(
        data: (series) {
          if (series.isEmpty) {
            return const Center(child: Text('No subscriptions/series found.'));
          }
          return ListView.builder(
            itemCount: series.length,
            itemBuilder: (context, index) {
              return SeriesCard(series: series[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, s) => Center(child: Text('Error loading series: $e')),
      ),
    );
  }
}
