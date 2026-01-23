import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';

abstract class FlashcardRepository {
  // 1: Fetching Data
  Future<List<Flashcard>> getDueCards(String deckId);
  Future<List<Deck>> getDecks();

  // 2: AI Magic
  // Returns a list of generated cards from a text source
Future<List<Flashcard>> generateFlashCards(String sourceText);

// 3. Saving Data
Future<void> saveDeck(String deckTitle, List<Flashcard> cards);
Future<void> updateCardProgress(Flashcard card);
}