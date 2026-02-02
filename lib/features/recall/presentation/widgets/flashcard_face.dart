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
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 9, 75, 129),
            Colors.blue,
            const Color.fromARGB(255, 67, 83, 163),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(offset: Offset(6, 6))],
      ),
      child: Stack(
        children: [
          // Top-Left Bracket
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black, width: 4),
                  left: BorderSide(color: Colors.black, width: 4),
                ),
              ),
            ),
          ),
          // Bottom-Right Bracket
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 4),
                  right: BorderSide(color: Colors.black, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -8,
            child: Opacity(
              opacity: 0.1, // Subtle
              child: Text(
                label == "QUESTION" ? "Q_01" : "ANS_01",
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -5,
                ),
              ),
            ),
          ),
          // Texture Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                'assets/images/checks-bg.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/images/blue-line.png',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sd_card,
                          color: Colors.black,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '// INPUT_STREAM: ',
                          style: const TextStyle(
                            fontVariations: [FontVariation.weight(450)],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: "ArchivoBlack",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontVariations: [FontVariation.weight(900)],
                      fontSize: 30,
                      color: Colors.white,
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
