import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/providers/parental_provider.dart';

class ParentalSettingsPage extends ConsumerWidget {
  const ParentalSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parentalProvider);
    final notifier = ref.read(parentalProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الرقابة'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSettingsCard(
            context,
            title: 'إدارة وقت الاستخدام',
            icon: Icons.timer_rounded,
            color: Colors.blue,
            children: [
              _buildSliderRow(
                title: 'المهلة اليومية',
                value: state.dailyTimeLimitMinutes.toDouble(),
                max: 300,
                label: state.dailyTimeLimitMinutes == 0 ? 'غير محدود' : '${state.dailyTimeLimitMinutes} دقيقة',
                onChanged: (v) => notifier.updateSettings(dailyTimeLimitMinutes: v.toInt()),
              ),
              _buildDropdownRow(
                title: 'عدد الغفوات المسموحة',
                value: state.allowedSnoozes,
                items: [0, 1, 2, 3, 5, 10],
                onChanged: (v) => notifier.updateSettings(allowedSnoozes: v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            title: 'التحكم في الوسائط',
            icon: Icons.tune_rounded,
            color: Colors.orange,
            children: [
              _buildSliderRow(
                title: 'الحد الأقصى للسطوع',
                value: state.maxBrightness,
                max: 1.0,
                min: 0.1,
                label: '${(state.maxBrightness * 100).toInt()}%',
                onChanged: (v) => notifier.updateSettings(maxBrightness: v),
              ),
              _buildSliderRow(
                title: 'الحد الأقصى للصوت',
                value: state.maxVolume,
                max: 1.0,
                label: '${(state.maxVolume * 100).toInt()}%',
                onChanged: (v) => notifier.updateSettings(maxVolume: v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            title: 'إحصائيات اليوم',
            icon: Icons.analytics_rounded,
            color: Colors.purple,
            children: [
              _buildStatRow('الوقت المستهلك اليوم', '${(state.consumedTimeSeconds / 60).toStringAsFixed(1)} دقيقة'),
              _buildStatRow('الغفوات المستخدمة', '${state.usedSnoozes} من أصل ${state.allowedSnoozes}'),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              notifier.incrementConsumedTime(-state.consumedTimeSeconds);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت إعادة تعيين وقت الاستخدام لليوم')),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded),
                SizedBox(width: 12),
                Text('إعادة تعيين اليوم (للتجربة)', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String title,
    required double value,
    required String label,
    required Function(double) onChanged,
    double min = 0,
    double max = 100,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        Slider(
          value: value < min ? min : (value > max ? max : value),
          min: min,
          max: max,
          activeColor: Colors.red,
          inactiveColor: Colors.red.withOpacity(0.1),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDropdownRow({
    required String title,
    required int value,
    required List<int> items,
    required Function(int) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        DropdownButton<int>(
          value: value,
          underline: const SizedBox(),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text('$i'))).toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ],
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
