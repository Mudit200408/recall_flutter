import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';

class DeckCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DeckCard({
    super.key,
    required this.deck,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            base64Decode(deck.deckImageUrl.split(',').last),
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat("SIZE", "${deck.cardCount} CARDS"),
                      _deleteButton(),
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

  Container _deleteButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red, width: 2),
        boxShadow: [
          BoxShadow(blurRadius: 0, offset: Offset(4, 4), color: Colors.red),
        ],
      ),
      child: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
        color: Colors.red,
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(shape: const RoundedRectangleBorder()),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
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
