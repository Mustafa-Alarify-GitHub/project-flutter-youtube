import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:ww/features/videos/presentation/providers/video_provider.dart';
import 'package:ww/features/videos/presentation/pages/main_wrapper.dart';

class AlbumSelectionPage extends ConsumerStatefulWidget {
  const AlbumSelectionPage({super.key});

  @override
  ConsumerState<AlbumSelectionPage> createState() => _AlbumSelectionPageState();
}

class _AlbumSelectionPageState extends ConsumerState<AlbumSelectionPage> {
  List<String> _tempSelectedIds = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(photoPermissionProvider);
    final allAlbumsAsync = ref.watch(allAlbumsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!permissionState.isAuth) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.video_collection_outlined, size: 80, color: Colors.red),
                ),
                const SizedBox(height: 24),
                const Text(
                  'مرحباً بك في يوتيوب جوري',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'يرجى إعطاء الصلاحية للوصول إلى فيديوهات جهازك لنتمكن من عرضها لك ولطفلك.',
                  style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                  ),
                  onPressed: () {
                    ref.read(photoPermissionProvider.notifier).requestPermission();
                  },
                  child: const Text(
                    'إعطاء الصلاحية',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تخصيص مجلدات العرض',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: allAlbumsAsync.when(
        data: (albums) {
          // Exclude the designated shorts folder from the main selection screen if needed,
          // but we can let them select it so the shorts are fetched, while we hide it from Home/Playlists.
          if (albums.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'لم يتم العثور على أي مجلدات تحتوي على فيديوهات في جهازك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => ref.refresh(allAlbumsProvider),
                      child: const Text('تحديث المجلدات'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Initialise temp selections from saved selectedAlbumsProvider or select all by default
          if (!_initialized) {
            final savedSelected = ref.read(selectedAlbumsProvider);
            if (savedSelected.isNotEmpty) {
              // Only keep saved IDs that still exist in the current folder list
              final albumIds = albums.map((a) => a.id).toList();
              _tempSelectedIds = savedSelected.where((id) => albumIds.contains(id)).toList();
            }
            // If still empty, select all folders by default
            if (_tempSelectedIds.isEmpty) {
              _tempSelectedIds = albums.map((a) => a.id).toList();
            }
            _initialized = true;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'اختر المجلدات التي ترغب في عرض فيديوهاتها في التطبيق. يمكنك تعديل هذا الاختيار لاحقاً من إعدادات الرقابة.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tempSelectedIds = albums.map((a) => a.id).toList();
                        });
                      },
                      child: const Text('تحديد الكل', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tempSelectedIds.clear();
                        });
                      },
                      child: const Text('إلغاء تحديد الكل', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: albums.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    final isChecked = _tempSelectedIds.contains(album.id);

                    return FutureBuilder<int>(
                      future: album.assetCountAsync,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0 && snapshot.connectionState == ConnectionState.done) {
                          // Skip folders with 0 videos
                          return const SizedBox.shrink();
                        }

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isChecked
                                  ? Colors.red.withOpacity(0.5)
                                  : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                              width: isChecked ? 2 : 1,
                            ),
                          ),
                          color: isChecked
                              ? Colors.red.withOpacity(isDark ? 0.15 : 0.05)
                              : (isDark ? Colors.grey[900] : Colors.white),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            title: Text(
                              album.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              '$count مقطع فيديو',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            value: isChecked,
                            activeColor: Colors.red,
                            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _tempSelectedIds.add(album.id);
                                } else {
                                  _tempSelectedIds.remove(album.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tempSelectedIds.isEmpty ? Colors.grey : Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                      ),
                      onPressed: _tempSelectedIds.isEmpty
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('الرجاء تحديد مجلد واحد على الأقل للتشغيل.')),
                              );
                            }
                          : () {
                              // Save configuration
                              ref.read(selectedAlbumsProvider.notifier).setSelected(_tempSelectedIds);
                              // Navigate to home feed wrapper
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const MainWrapper()),
                              );
                            },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'شغل الفيديوهات الآن',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, s) => Center(child: Text('حدث خطأ أثناء تحميل المجلدات: $e')),
      ),
    );
  }
}
