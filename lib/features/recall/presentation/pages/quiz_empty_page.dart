import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';

import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class QuizEmptyPage extends StatefulWidget {
  final Deck deck;
  const QuizEmptyPage({super.key, required this.deck});

  // Neo-Brutalist Colors
  static const Color primaryColor = Color(0xFFCCFF00);
  static const Color blackColor = Colors.black;
  static const Color backgroundColor = Colors.white;

  @override
  State<QuizEmptyPage> createState() => _QuizEmptyPageState();
}

class _QuizEmptyPageState extends State<QuizEmptyPage> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    // Assuming cards reset daily based on lastGeneratedDate.
    // If not available, we assume 24 hours from now as a fallback or end of day?
    // Let's assume the reset happens at midnight or 24h after generation.
    // Given spaced repetition often works on day boundaries, let's target next midnight if generated today,
    // or simply 24 hours after last generation.
    // For simplicity and common app behavior: Target next midnight.
    // Or simpler: lastGeneratedDate + 24 hours.

    // UPDATE: The DeckBloc generates new cards after 20 hours, so we align the timer to that.
    final lastGen = widget.deck.lastGeneratedDate ?? DateTime.now();
    final target = lastGen.add(const Duration(hours: 20));

    final difference = target.difference(now);

    if (difference.isNegative) {
      // Should be ready now? But if it's empty, maybe backend hasn't updated or synced.
      // We'll show 00:00:00 or reload prompt.
      setState(() {
        _timeLeft = Duration.zero;
      });
    } else {
      setState(() {
        _timeLeft = difference;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizEmptyPage.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // 1. AlwaysScrollable ensures you can bounce/scroll even if content fits exactly
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              // 2. This forces the scroll view to be AT LEAST the size of the screen
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                // 3. This centers the card if it fits, but lets it expand if it doesn't
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0.r,
                    vertical: 40.0.r,
                  ),
                  child: Container(
                    // 4. Set a max width for tablets, but let height be dynamic
                    constraints: BoxConstraints(maxWidth: 400.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: QuizEmptyPage.blackColor,
                        width: 4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: QuizEmptyPage.blackColor,
                          offset: Offset(8, 8),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Shrink-wrap the height
                      children: [
                        // --- HEADER SECTION ---
                        Container(
                          // REMOVED fixed height: 220.h
                          // Use minHeight to keep aspect ratio but allow growth
                          constraints: BoxConstraints(minHeight: 200.h),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromARGB(255, 95, 92, 92),
                                Color(0xFF2A2A2A),
                              ],
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: QuizEmptyPage.blackColor,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/images/checks-bg.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.r),
                                child: Icon(
                                  Icons.quiz_outlined,
                                  size: 100.r,
                                  color: Colors.white24,
                                ),
                              ),
                              Positioned(
                                top: 16.r,
                                left: 16.r,
                                child: _buildNeoBadge('EMPTY CARDS'),
                              ),
                            ],
                          ),
                        ),

                        // --- CONTENT SECTION ---
                        Padding(
                          padding: EdgeInsets.all(24.0.r),
                          child: Column(
                            children: [
                              Text(
                                'NO FLASHCARDS\nAVAILABLE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  height: 0.9,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              SizedBox(height: 20.scale()),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.scale(),
                                  vertical: 10.scale(),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'NEXT DECK IN: ${_formatDuration(_timeLeft)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: QuizEmptyPage.primaryColor,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 32.scale()),
                              Text(
                                "Stats from Previous Quiz:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16.scale()),
                              // WRAP prevents overflow if badges get too wide
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12.scale(),
                                runSpacing: 12.scale(),
                                children: [
                                  _buildStatBadge(
                                    'REVIEW',
                                    widget.deck.hardCount,
                                    Colors.orange,
                                  ),
                                  _buildStatBadge(
                                    'NAILED',
                                    widget.deck.easyCount,
                                    Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // --- BUTTON SECTION ---
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16.scale(),
                            0,
                            16.scale(),
                            24.scale(),
                          ),
                          child: AnimatedButton(
                            text: 'GO TO HOME',
                            icon: Icons.keyboard_return,
                            iconSide: 'left',
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNeoBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 4.r),
      decoration: BoxDecoration(
        color: QuizEmptyPage.primaryColor,
        border: Border.all(color: QuizEmptyPage.blackColor, width: 2),
        boxShadow: const [
          BoxShadow(color: QuizEmptyPage.blackColor, offset: Offset(3, 3)),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 100.w),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: QuizEmptyPage.blackColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: QuizEmptyPage.blackColor,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontVariations: [FontVariation.weight(900)],
                color: color,
                height: 1.0,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontVariations: [FontVariation.weight(900)],
                color: color,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
