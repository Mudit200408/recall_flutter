import 'package:flutter/material.dart';

class FlashcardFace extends StatelessWidget {
  final String text;
  final Color color;
  final String label; // "Question" or "Answer"

  const FlashcardFace({
    super.key,
    required this.text,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0), // Off-white/Paper color
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(offset: Offset(6, 6))],
      ),
      child: Stack(
        children: [
          // Texture Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/png/brushed-alum-dark.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          // Your Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
