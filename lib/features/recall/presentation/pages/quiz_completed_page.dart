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
  final bool isGuest;

  const QuizCompletedPage({
    super.key,
    required this.deck,
    required this.easyCount,
    required this.hardCount,
    required this.failCount,
    this.isDeckDeleted = false,
    required this.isGuest,
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
                        constraints: BoxConstraints(maxWidth: 400.w),
                        child: Container(
                          margin: EdgeInsets.all(16.r),
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
                              if (deck.imageUrl != null)
                                SizedBox(
                                  height: 250.h,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      deck.deckImageUrl.startsWith('data:image')
                                          ? Image.memory(
                                              base64Decode(
                                                deck.deckImageUrl
                                                    .split(',')
                                                    .last,
                                              ),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _buildErrorPlaceholder(),
                                            )
                                          : Image.network(
                                              deck.deckImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _buildErrorPlaceholder(),
                                            ),
                                    ],
                                  ),
                                ),

                              // Content
                              Padding(
                                padding: EdgeInsets.all(16.r),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      deck.title.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontVariations: [
                                          FontVariation.weight(900),
                                        ],
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),

                                    Container(
                                      width: double.infinity,
                                      height: 1,
                                      color: Colors.grey[300],
                                    ),
                                    SizedBox(height: 16.h),
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
                                    SizedBox(height: 8.h),
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
                          left: 16.0.r,
                          right: 16.0.r,
                          bottom: 10.r,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 400.w),
                          child: AnimatedButton(
                            text: "BACK TO DECKS",
                            onTap: () => Navigator.pop(
                              context,
                              isDeckDeleted ? deck.id : null,
                            ),
                            icon: Icons.arrow_forward,
                            iconSide: 'right',
                            isGuest: isGuest,
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
        child: Icon(Icons.broken_image, color: Colors.white, size: 40.r),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(12.r),
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
