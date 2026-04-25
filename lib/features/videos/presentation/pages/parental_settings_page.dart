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
        title: const Text('إعدادات الرقابة الأبوية'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('إدارة الوقت'),
          ListTile(
            title: const Text('مهلة التشغيل اليومية (بالدقائق)'),
            subtitle: Text(state.dailyTimeLimitMinutes == 0 ? 'غير محدود' : '${state.dailyTimeLimitMinutes} دقيقة'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: state.dailyTimeLimitMinutes.toDouble(),
                min: 0,
                max: 180, // max 3 hours
                divisions: 18,
                label: '${state.dailyTimeLimitMinutes}',
                onChanged: (val) => notifier.updateSettings(dailyTimeLimitMinutes: val.toInt()),
              ),
            ),
          ),
          ListTile(
            title: const Text('عدد الغفوات المسموحة (زيادة الوقت)'),
            subtitle: Text('${state.allowedSnoozes} مرات'),
            trailing: DropdownButton<int>(
              value: state.allowedSnoozes,
              items: List.generate(6, (index) => DropdownMenuItem(value: index, child: Text('$index'))),
              onChanged: (val) => notifier.updateSettings(allowedSnoozes: val),
            ),
          ),
          const Divider(),
          
          _buildSectionHeader('الإضاءة والصوت'),
          ListTile(
            title: const Text('الحد الأقصى لسطوع التطبيق'),
            subtitle: Text('${(state.maxBrightness * 100).toInt()}%'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: state.maxBrightness,
                min: 0.1,
                max: 1.0,
                onChanged: (val) => notifier.updateSettings(maxBrightness: val),
              ),
            ),
          ),
          ListTile(
            title: const Text('الحد الأقصى لمستوى الصوت'),
            subtitle: Text('${(state.maxVolume * 100).toInt()}%'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: state.maxVolume,
                min: 0.0,
                max: 1.0,
                onChanged: (val) => notifier.updateSettings(maxVolume: val),
              ),
            ),
          ),
          const Divider(),
          
          _buildSectionHeader('إحصائيات اليوم'),
          ListTile(
            title: const Text('الوقت المستهلك اليوم'),
            trailing: Text('${(state.consumedTimeSeconds / 60).toStringAsFixed(1)} دقيقة'),
          ),
          ListTile(
            title: const Text('الغفوات المستخدمة'),
            trailing: Text('${state.usedSnoozes} / ${state.allowedSnoozes}'),
          ),
          
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () {
              // Reset daily stats for testing purposes
              notifier.incrementConsumedTime(-state.consumedTimeSeconds);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إعادة تصوير استهلاك الوقت (للتجربة)')));
            },
            child: const Text('إعادة تعيين استهلاك اليوم (للتجربة)'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }
}
