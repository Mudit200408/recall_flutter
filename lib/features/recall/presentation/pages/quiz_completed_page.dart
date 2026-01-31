import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';

class QuizCompletedPage extends StatelessWidget {
  final Deck deck;
  const QuizCompletedPage({super.key, required this.deck});

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
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 1.3,
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
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Image
                  SizedBox(
                    height: 250,
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
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          height: 1,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 10,
                ),
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xff9de749),
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "BACK TO DECKS",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
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
}

extension on Deck {
  // Helper to fallback safely
  String get deckImageUrl => imageUrl ?? '';
}
