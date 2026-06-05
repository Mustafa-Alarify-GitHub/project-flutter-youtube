import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class MathGateDialog extends StatefulWidget {
  const MathGateDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => const MathGateDialog(),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
    return result ?? false;
  }

  @override
  State<MathGateDialog> createState() => _MathGateDialogState();
}

class _MathGateDialogState extends State<MathGateDialog> {
  late int num1;
  late int num2;
  late int correctAnswer;
  final TextEditingController _controller = TextEditingController();
  bool showError = false;

  @override
  void initState() {
    super.initState();
    _generateMathNode();
  }

  void _generateMathNode() {
    final rand = Random();
    num1 = rand.nextInt(7) + 3; // 3 to 9
    num2 = rand.nextInt(7) + 3;
    correctAnswer = num1 * num2;
    setState(() {});
  }

  void _verify() {
    final input = int.tryParse(_controller.text);
    if (input == correctAnswer) {
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        showError = true;
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security_rounded, color: Colors.red, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'بوابة الوالدين',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'أجب على السؤال التالي للتأكد من أنك لست طفلاً:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Text(
                  '$num1 × $num2 = ?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '---',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.3)),
                  errorText: showError ? 'إجابة غير صحيحة' : null,
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _verify(),
                autofocus: true,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('تحقق الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
