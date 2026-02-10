import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'MISSION\nACCOMPLISHED',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 38,
                          //fontFamily: 'ArchivoBlack',
                          color: Colors.black,
                          fontVariations: const [FontVariation('wght', 900)],
                        ),
                      ),
                      const Spacer(),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 400.scale()),
                        child: Container(
                          margin: EdgeInsets.all(16.scale()),
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
                                height: 250.scale(),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (deck.imageUrl != null)
                                      deck.deckImageUrl.startsWith('data:image')
                                          ? Image.memory(
                                              base64Decode(
                                                deck.deckImageUrl
                                                    .split(',')
                                                    .last,
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
                                        child: Center(
                                          child: Icon(
                                            Icons.gamepad,
                                            color: Colors.white,
                                            size: 48.scale(),
                                          ),
                                        ),
                                      ),
                                    // Overlay Gradient
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 60.scale(),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black87,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Content
                              Padding(
                                padding: EdgeInsets.all(16.scale()),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      deck.title.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 20.scale(),
                                        fontVariations: [
                                          FontVariation.weight(900),
                                        ],
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 8.scale()),

                                    Container(
                                      width: double.infinity,
                                      height: 1,
                                      color: Colors.grey[300],
                                    ),
                                    SizedBox(height: 16.scale()),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatItem(
                                          "KNEW IT",
                                          easyCount,
                                          Colors.green,
                                        ),
                                        _buildStatItem(
                                          "REVIEW",
                                          hardCount + failCount,
                                          Colors.orange,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.scale()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16.0.scale(),
                          right: 16.0.scale(),
                          bottom: 10.scale(),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 400.scale()),
                          child: AnimatedButton(
                            text: "BACK TO DECKS",
                            onTap: () => Navigator.pop(
                              context,
                              isDeckDeleted ? deck.id : null,
                            ),
                            icon: Icons.arrow_forward,
                            iconSide: 'right',
                          ),
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Icon(Icons.broken_image, color: Colors.white, size: 40.scale()),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(12.scale()),
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
