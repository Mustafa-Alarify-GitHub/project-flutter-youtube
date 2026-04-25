import 'package:flutter/material.dart';
import 'dart:math';

class MathGateDialog extends StatefulWidget {
  const MathGateDialog({Key? key}) : super(key: key);

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MathGateDialog(),
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
    num1 = rand.nextInt(9) + 4; // 4 to 12
    num2 = rand.nextInt(9) + 4;
    correctAnswer = num1 * num2;
    setState(() {});
  }

  void _verify() {
    final input = int.tryParse(_controller.text);
    if (input == correctAnswer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        showError = true;
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock, color: Colors.red),
          SizedBox(width: 8),
          Text('بوابة الآباء', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('يرجى حل المسألة الرياضية التالية للمتابعة:', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            '$num1 × $num2 = ?',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'الإجابة',
              errorText: showError ? 'إجابة خاطئة، حاول مرة أخرى!' : null,
            ),
            onSubmitted: (_) => _verify(),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _verify,
          child: const Text('تحقق', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
