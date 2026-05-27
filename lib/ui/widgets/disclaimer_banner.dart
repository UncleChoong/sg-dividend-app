import 'package:flutter/material.dart';
import 'package:sg_dividend/ui/disclaimer_screen.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3CD),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DisclaimerScreen())),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF856404)),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Educational tool — not financial advice. Tap to read more.',
              style: TextStyle(fontSize: 12, color: Color(0xFF856404)),
            )),
          ]),
        ),
      ),
    );
  }
}
