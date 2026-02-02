import 'package:flutter/material.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';

import 'package:recall/features/recall/domain/entities/deck.dart';

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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 700,
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
                        flex: 1,
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
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
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
                                  child: const Text(
                                    'EMPTY CARDS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.quiz_outlined,
                                size: 120,
                                color: Colors.white24,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Text Content Section
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'NO FLASHCARDS\nAVAILABLE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontVariations: [FontVariation.weight(900)],
                                  height: 0.9,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
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
                      const SizedBox(height: 8),
                      Row(
                        spacing: 8,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatBadge('FAIL', deck.failCount, Colors.red),
                          _buildStatBadge(
                            'HARD',
                            deck.hardCount,
                            Colors.orange,
                          ),
                          _buildStatBadge('EASY', deck.easyCount, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Bottom Button Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
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
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: blackColor, width: 3),
        boxShadow: const [
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
          const SizedBox(height: 4),
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
