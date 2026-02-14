import 'package:flutter/material.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

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
      constraints: BoxConstraints(minHeight: 300.r),
      // Main Card Chassis
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F6),
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
      ),
      child: Column(
        // Changed Stack to Column to ensure proper layout structure
        children: [
          // 1. Header Bar (Fixed Height)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: const BoxDecoration(
              color: Color(0xFFF9E006), // brutal-yellow
              border: Border(bottom: BorderSide(color: Colors.black, width: 4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.memory, color: Colors.black, size: 20.r),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          label == "QUESTION"
                              ? "SYSTEM_QUERY"
                              : "SYSTEM_RESULT",
                          style: TextStyle(
                            color: Colors.black,
                            fontVariations: const [FontVariation.weight(900)],
                            fontSize: 18,
                            letterSpacing: -0.5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
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

          // 2. CRT Screen Area (Expanded to fill remaining space)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B), // brutal-slate
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Scanlines Overlay (Behind text)
                  Positioned.fill(child: _buildScanlines()),

                  // Main Scrollable Content
                  Positioned.fill(
                    child: Column(
                      children: [
                        // Status Bar (Fixed at top of screen)
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    textScaler: TextScaler.linear(1.0),
                                  ),
                                  Text(
                                    "PKT_LOSS: ${label == "QUESTION" ? '0%' : '100%'}",
                                    style: const TextStyle(
                                      color: Color(0x9906F957),
                                      fontSize: 12,
                                    ),
                                    textScaler: TextScaler.linear(1.0),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.r),
                              Container(
                                width: 30.r,
                                height: 4.r,
                                color: const Color(0xFF06F957),
                              ),
                              SizedBox(height: 12.h),
                            ],
                          ),
                        ),

                        // Scrollable Text Area
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                SizedBox(height: 20.h), // Bottom buffer
                              ],
                            ),
                          ),
                        ),

                        // Prompt Box (Fixed at bottom of screen)
                        Padding(
                          padding: EdgeInsets.all(16.r),
                          child: _buildPromptCard(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard() {
    return Container(
      padding: EdgeInsets.all(10.r),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: const Border(
          left: BorderSide(color: Color(0xFF06F957), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "> WAITING FOR INPUT...",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
            textScaler: TextScaler.linear(1.0),
          ),
          Text(
            label == "QUESTION" ? "> " : "> DATA DECRYPTED SUCCESSFULLY.",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
            textScaler: TextScaler.linear(1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildScanlines() {
    return Column(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.15),
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
