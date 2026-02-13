import 'package:flutter/material.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class FlashcardFace extends StatelessWidget {
  final String text;
  final Color
  color; // You can still pass this, but the theme is fixed to Brutalist
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
      // Main Card Chassis
      decoration: BoxDecoration(
        color: const Color(
          0xFFF5F8F6,
        ), // background-light (or Zinc-800 for dark mode)
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Header Bar (Yellow)
              Container(
                padding: EdgeInsets.all(21.scale()),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9E006), // brutal-yellow
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.memory,
                          color: Colors.black,
                          size: 20.scale(),
                        ),
                        SizedBox(width: 8.scale()),
                        Text(
                          label == "QUESTION"
                              ? "SYSTEM_QUERY"
                              : "SYSTEM_RESULT",
                          style: TextStyle(
                            color: Colors.black,
                            fontVariations: const [FontVariation.weight(900)],
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: Colors.black,
                      child: Text(
                        label == "QUESTION" ? "ID_049" : "ID_050",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Screen/Body Area (The CRT Screen)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // brutal-slate
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Scanlines Overlay
                      Positioned.fill(child: _buildScanlines()),

                      Padding(
                        padding: EdgeInsets.all(16.scale()),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  label == "QUESTION"
                                      ? "STATUS: ENCRYPTED"
                                      : "STATUS: DECRYPTED",
                                  style: const TextStyle(
                                    color: Color(0x9906F957),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "PKT_LOSS: ${label == "QUESTION" ? '0%' : '100%'}",
                                  style: const TextStyle(
                                    color: Color(0x9906F957),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 23.scale()),
                            // The Pulsing Indicator
                            Container(
                              width: 30.scale(),
                              height: 4.scale(),
                              color: const Color(0xFF06F957),
                            ),
                            SizedBox(height: 12.scale()),
                            // Main Text Content — fills remaining space, scrolls if needed
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Text(
                                  text.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12.scale()),
                            // Prompt Box
                            _buildPromptCard(),
                            SizedBox(height: 10.scale()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Industrial Screws
          _buildScrew(top: 8, left: 8),
          _buildScrew(top: 8, right: 8),
          _buildScrew(bottom: 8, left: 8),
          _buildScrew(bottom: 8, right: 8),
        ],
      ),
    );
  }

  Container _buildPromptCard() {
    return Container(
      padding: EdgeInsets.all(10.scale()),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: const Border(
          left: BorderSide(color: Color(0xFF06F957), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "> WAITING FOR INPUT...",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label == "QUESTION" ? "> " : "> DATA DECRYPTED SUCCESSFULLY.",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build the industrial screw heads
  Widget _buildScrew({
    double? top,
    double? left,
    double? right,
    double? bottom,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 10.scale(),
        height: 10.scale(),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Center(
          child: Transform.rotate(
            angle: 0.78, // 45 degrees
            child: Container(width: 10, height: 1, color: Colors.black),
          ),
        ),
      ),
    );
  }

  // Helper to build the CRT lines texture
  Widget _buildScanlines() {
    return Column(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
