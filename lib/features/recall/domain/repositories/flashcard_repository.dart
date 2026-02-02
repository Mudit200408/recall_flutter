import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';

abstract class FlashcardRepository {
  // 1: Fetching Data
  Future<List<Flashcard>> getDueCards(String deckId);
  Future<List<Deck>> getDecks();

  // 2: AI Magic
  // Returns a list of generated cards from a text source
  Future<List<Flashcard>> generateFlashCards(
    String topic,
    int count,
    bool useImages,
  );
  // 3. Saving Data
  Future<void> saveDeck(
    String deckTitle,
    List<Flashcard> cards, {
    String? imageUrl,
    bool useImages = false,
    String topic = '',
    int scheduledDays = 0,
    int dailyCardCount = 0,
    int easyCount = 0,
    int hardCount = 0,
    int failCount = 0,
  });
  Future<void> updateCardProgress(Flashcard card);

  // 4. Delete Decks
  Future<void> deleteDeck(String deckId);

  Future<void> generateMoreCards(Deck deck);

  Future<void> updateDeckStats(
    String deckId, {
    int easyIncrement = 0,
    int hardIncrement = 0,
    int failIncrement = 0,
  });
}
