import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:recall/core/theme/app_colors.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/presentation/widgets/progress_bar.dart';
import 'package:recall/features/recall/presentation/widgets/square_button.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class DeckCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isGuest;

  const DeckCard({
    super.key,
    required this.deck,
    required this.onTap,
    required this.onDelete,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image
            if (deck.imageUrl != null)
              SizedBox(
                height: 200.h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    deck.deckImageUrl.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(deck.deckImageUrl.split(',').last),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
                          )
                        : Image.network(
                            deck.deckImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
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
                      fontSize: 20,
                      fontVariations: [FontVariation.weight(900)],
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 8.h),
                  _builProgressBar(
                    "PROGRESS",
                    "${deck.daysGenerated}/${deck.scheduledDays} DAYS",
                    progress:
                        deck.daysGenerated /
                        (deck.scheduledDays == 0 ? 1 : deck.scheduledDays),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat("DECK SIZE", "${deck.dailyCardCount} CARDS"),

                      SquareButton(
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    String label,
    String value, {
    bool showBar = false,
    double progress = 0.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        if (showBar) ...[
          SizedBox(height: 4.h),
          Container(
            width: 80.w,
            height: 6.h,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              color: const Color(0xFFCCFF00), // Neo-brutalist green
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _builProgressBar(String label, String value, {double progress = 0.0}) {
    final bool isSkipped = deck.skippedDays > 0;
    final color = isSkipped ? Colors.red : accentColor(isGuest);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${deck.daysGenerated}/${deck.scheduledDays} DAYS",
              style: TextStyle(
                fontSize: 12,
                fontVariations: [FontVariation.weight(900)],
                fontStyle: FontStyle.italic,
                color: Colors.black,
              ),
            ),
            if (isSkipped)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.r, vertical: 2.r),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  "SKIPPED!",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: ProgressBar(
            progress: progress,
            color: color,
            isGuest: isGuest,
          ),
        ),
      ],
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
}

extension on Deck {
  // Helper to fallback safely
  String get deckImageUrl => imageUrl ?? '';
}
