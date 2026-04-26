import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ww/features/videos/presentation/pages/parental_settings_page.dart';
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
      final pState = ref.read(parentalProvider);
      final isLimitReached = pState.dailyTimeLimitMinutes > 0 && 
                             pState.consumedTimeSeconds >= (pState.dailyTimeLimitMinutes * 60);
      
      // Only increment if limit is NOT reached
      if (!isLimitReached) {
        ref.read(parentalProvider.notifier).incrementConsumedTime(1);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final parentalState = ref.watch(parentalProvider);
    
    // Calculate if time limit is reached
    final bool isTimeUp = parentalState.dailyTimeLimitMinutes > 0 && 
                          parentalState.consumedTimeSeconds >= (parentalState.dailyTimeLimitMinutes * 60);

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
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A1A),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.withOpacity(0.2), width: 2),
                    ),
                    child: const Icon(Icons.auto_awesome_motion_rounded, size: 64, color: Colors.red),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'وقت الاستراحة!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'لقد استنفدت وقتك اليوم (${parentalState.dailyTimeLimitMinutes} دقيقة)',
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  if (parentalState.usedSnoozes < parentalState.allowedSnoozes)
                    _buildActionButton(
                      icon: Icons.add_alarm_rounded,
                      label: 'تمديد الوقت (5 دقائق إضافية)',
                      onPressed: () async {
                        final success = await MathGateDialog.show(context);
                        if (success) {
                          ref.read(parentalProvider.notifier).useSnooze(5);
                        }
                      },
                    ),
                  
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.settings_rounded,
                    label: 'دخول الوالدين للإعدادات',
                    isSecondary: true,
                    onPressed: () async {
                      final success = await MathGateDialog.show(context);
                      if (success) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ParentalSettingsPage()),
                        );
                      }
                    },
                  ),

                  if (parentalState.usedSnoozes >= parentalState.allowedSnoozes)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'تم استهلاك جميع الغفوات (${parentalState.allowedSnoozes}) المتاحة.',
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        boxShadow: [
          if (!isSecondary)
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white.withOpacity(0.1) : Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
