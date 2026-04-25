import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/providers/parental_provider.dart';
import 'package:ww/features/videos/presentation/widgets/math_gate_dialog.dart';

class ParentalWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const ParentalWrapper({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<ParentalWrapper> createState() => _ParentalWrapperState();
}

class _ParentalWrapperState extends ConsumerState<ParentalWrapper> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      ref.read(parentalProvider.notifier).incrementConsumedTime(1);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final parentalState = ref.watch(parentalProvider);
    
    // Calculate if time limit is reached
    bool isTimeUp = false;
    if (parentalState.dailyTimeLimitMinutes > 0) {
      isTimeUp = parentalState.consumedTimeSeconds >= (parentalState.dailyTimeLimitMinutes * 60);
    }

    return Stack(
      children: [
        widget.child,
        
        // Brightness Overlay (Implements max brightness limit)
        if (parentalState.maxBrightness < 1.0)
          IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(1.0 - parentalState.maxBrightness),
            ),
          ),

        // Lock Screen Overlay
        if (isTimeUp)
          Material(
            color: Colors.black,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_off, size: 80, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'انتهى الوقت المسموح لليوم!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تم استهلاك ${parentalState.dailyTimeLimitMinutes} دقيقة.',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  
                  // Snooze Button with Math Gate
                  if (parentalState.usedSnoozes < parentalState.allowedSnoozes)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () async {
                        final success = await MathGateDialog.show(context);
                        if (success) {
                          // Allow 5 minutes snooze
                          ref.read(parentalProvider.notifier).useSnooze(5);
                        }
                      },
                      icon: const Icon(Icons.add_alarm, color: Colors.white),
                      label: Text(
                        'طلب وقت إضافي (غفوة) (${parentalState.allowedSnoozes - parentalState.usedSnoozes} متبقي)',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  
                  if (parentalState.usedSnoozes >= parentalState.allowedSnoozes)
                    const Text(
                      'لا يمكن طلب وقت إضافي أكثر لليوم.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () async {
                      final success = await MathGateDialog.show(context);
                      if (success) {
                        // In a real app we might open settings, 
                        // here we just give a hint that parent can increase daily limit
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يمكنك تغيير الإعدادات من أيقونة القفل في الصفحة الرئيسية')),
                        );
                      }
                    },
                    child: const Text('دخول الوالدين لتغيير الإعدادات', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
