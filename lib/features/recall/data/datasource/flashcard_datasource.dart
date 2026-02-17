import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';

abstract class FlashcardDataSource {
  Future<List<Flashcard>> getDueCards(String deckId);
  Future<List<Deck>> getDecks();

  // Save a brand new deck
  Future<void> saveDeck(
    String deckTitle,
    String difficultyLevel,
    List<Flashcard> cards, {
    String? imageUrl,
    bool useImages = false,
    int scheduledDays = 0,
    int dailyCardCount = 0,
    int easyCount = 0,
    int hardCount = 0,
  });

  // Save NEW cards to an EXISTING deck (For "Generate More")
  Future<void> addCards(String deckId, List<Flashcard> cards);

  Future<void> updateCardProgress(Flashcard card);
  Future<void> deleteDeck(String deckId);

  Future<void> updateDeckStats(
    String deckId, {
    int easyIncrement = 0,
    int hardIncrement = 0,
  });

  Future<void> registerSkippedDay(String deckId, int daysSkipped);

  Future<void> markDeckPlayed(String deckId);
}
