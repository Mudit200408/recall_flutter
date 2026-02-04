import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';

class QuizCompletedPage extends StatelessWidget {
  final Deck deck;
  final int easyCount;
  final int hardCount;
  final int failCount;
  final bool isDeckDeleted;

  const QuizCompletedPage({
    super.key,
    required this.deck,
    required this.easyCount,
    required this.hardCount,
    required this.failCount,
    this.isDeckDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MISSION\nACCOMPLISHED',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 38,
                fontFamily: 'ArchivoBlack',
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    offset: const Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Image
                  SizedBox(
                    height: 400,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (deck.imageUrl != null)
                          deck.deckImageUrl.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(
                                    deck.deckImageUrl.split(',').last,
                                  ),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildErrorPlaceholder(),
                                )
                              : Image.network(
                                  deck.deckImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildErrorPlaceholder(),
                                )
                        else
                          Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.gamepad,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        // Overlay Gradient
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black87],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontVariations: [FontVariation.weight(900)],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          height: 1,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem("EASY", easyCount, Colors.green),
                            _buildStatItem("HARD", hardCount, Colors.orange),
                            _buildStatItem("FAIL", failCount, Colors.red),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 10,
              ),
              child: AnimatedButton(
                text: "BACK TO DECKS",
                onTap: () =>
                    Navigator.pop(context, isDeckDeleted ? deck.id : null),
                icon: Icons.arrow_forward,
                iconSide: 'right',
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "$count",
            style: TextStyle(
              fontSize: 24,
              fontVariations: [FontVariation.weight(900)],
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontVariations: [FontVariation.weight(900)],
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Deck {
  // Helper to fallback safely
  String get deckImageUrl => imageUrl ?? '';
}
