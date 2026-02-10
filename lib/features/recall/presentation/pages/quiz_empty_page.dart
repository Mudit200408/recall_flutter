import 'dart:async';
import 'dart:ui';
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
      body: SingleChildScrollView(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main Content
            Center(
              child: Padding(
                padding: EdgeInsets.all(24.0.scale()),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 400.scale(),
                    maxHeight: 700.scale(),
                  ),
                  child: Container(
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
                      children: [
                        // Top Grid Section
                        Expanded(
                          flex: 3,
                          child: Container(
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
                                Image.asset(
                                  'assets/images/checks-bg.png',
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                // Slot Badge
                                Positioned(
                                  top: 16.scale(),
                                  left: 16.scale(),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.scale(),
                                      vertical: 4.scale(),
                                    ),
                                    decoration: BoxDecoration(
                                      color: QuizEmptyPage.primaryColor,
                                      border: Border.all(
                                        color: QuizEmptyPage.blackColor,
                                        width: 3,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: QuizEmptyPage.blackColor,
                                          offset: Offset(4, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'EMPTY CARDS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.scale(),
                                      ),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 120.scale(),
                                  color: Colors.white24,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Text Content Section
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: EdgeInsets.all(24.0.scale()),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'NO FLASHCARDS\nAVAILABLE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontVariations: [FontVariation.weight(900)],
                                    height: 0.9,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                                SizedBox(height: 20.scale()),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.scale(),
                                    vertical: 8.scale(),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'NEXT DECK IN: ${_formatDuration(_timeLeft)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: QuizEmptyPage.primaryColor,
                                      letterSpacing: 1.2,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          "Stats from Previous Quiz:",
                          style: TextStyle(
                            fontSize: 18,
                            fontVariations: [FontVariation.weight(900)],
                            color: Colors.black,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 8.scale()),
                        Row(
                          spacing: 8.scale(),
                          mainAxisAlignment: MainAxisAlignment.center,
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
                        const Spacer(),
                        // Bottom Button Section
                        Padding(
                          padding: EdgeInsets.all(16.0.scale()),
                          child: AnimatedButton(
                            text: 'GO BACK TO HOME',
                            icon: Icons.keyboard_return,
                            iconSide: 'left',
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 100.scale()),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.scale()),
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
            SizedBox(height: 4.scale()),
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
