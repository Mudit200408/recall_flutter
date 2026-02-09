import 'package:flutter/material.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';

import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class QuizEmptyPage extends StatelessWidget {
  final Deck deck;
  const QuizEmptyPage({super.key, required this.deck});

  // Neo-Brutalist Colors
  static const Color primaryColor = Color(0xFFCCFF00);
  static const Color blackColor = Colors.black;
  static const Color backgroundColor = Colors.white;

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
                      border: Border.all(color: blackColor, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: blackColor,
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
                                bottom: BorderSide(color: blackColor, width: 4),
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
                                      color: primaryColor,
                                      border: Border.all(
                                        color: blackColor,
                                        width: 3,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: blackColor,
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
                                Text(
                                  'COME BACK LATER...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 1.2,
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
                            _buildStatBadge('FAIL', deck.failCount, Colors.red),
                            _buildStatBadge(
                              'HARD',
                              deck.hardCount,
                              Colors.orange,
                            ),
                            _buildStatBadge(
                              'EASY',
                              deck.easyCount,
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
    return Container(
      width: 80.scale(),
      padding: EdgeInsets.symmetric(vertical: 12.scale()),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: blackColor, width: 3),
        boxShadow: [
          BoxShadow(color: blackColor, offset: Offset(4, 4), blurRadius: 0),
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
              color: blackColor,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
