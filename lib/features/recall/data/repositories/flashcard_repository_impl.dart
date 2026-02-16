import 'package:recall/features/recall/data/datasource/local_flashcard_datasource.dart';
import 'package:recall/features/recall/data/datasource/remote_flashcard_datasource.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/features/recall/domain/services/ai_service.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final RemoteFlashcardDataSource remoteFlashcardDataSource;
  final LocalFlashcardDatasource localFlashcardDatasource;
  final AiService aiService;
  final bool isGuestMode;

  FlashcardRepositoryImpl({
    required this.remoteFlashcardDataSource,
    required this.localFlashcardDatasource,
    required this.aiService,
    required this.isGuestMode,
  });

  @override
  Future<void> deleteDeck(String deckId) {
    if (isGuestMode) {
      return localFlashcardDatasource.deleteDeck(deckId);
    } else {
      return remoteFlashcardDataSource.deleteDeck(deckId);
    }
  }

  @override
  Future<List<Flashcard>> generateFlashCards(String title, int count) async {
    final contentList = await aiService.generateFlashcards(title, count);

    return contentList
        .map(
          (content) => Flashcard.newCard(
            id: '',
            deckId: '',
            front: content.front,
            back: content.back,
          ),
        )
        .toList();
  }

  @override
  Future<void> generateMoreCards(Deck deck) async {
    final contentList = await aiService.generateFlashcards(
      deck.title,
      deck.dailyCardCount,
    );

    final newCards = contentList
        .map(
          (content) => Flashcard.newCard(
            id: '',
            deckId: '',
            front: content.front,
            back: content.back,
          ),
        )
        .toList();

    if (isGuestMode) {
      return localFlashcardDatasource.addCards(deck.id, newCards);
    } else {
      return remoteFlashcardDataSource.addCards(deck.id, newCards);
    }
  }

  @override
  Future<List<Deck>> getDecks() {
    if (isGuestMode) {
      return localFlashcardDatasource.getDecks();
    } else {
      return remoteFlashcardDataSource.getDecks();
    }
  }

  @override
  Future<List<Flashcard>> getDueCards(String deckId) {
    if (isGuestMode) {
      return localFlashcardDatasource.getDueCards(deckId);
    } else {
      return remoteFlashcardDataSource.getDueCards(deckId);
    }
  }

  @override
  Future<void> registerSkippedDay(String deckId, int daysSkipped) {
    if (isGuestMode) {
      return localFlashcardDatasource.registerSkippedDay(deckId, daysSkipped);
    } else {
      return remoteFlashcardDataSource.registerSkippedDay(deckId, daysSkipped);
    }
  }

  @override
  Future<void> saveDeck(
    String deckTitle,
    List<Flashcard> cards, {
    String? imageUrl,
    bool useImages = false,
    int scheduledDays = 0,
    int dailyCardCount = 0,
    int easyCount = 0,
    int hardCount = 0,
    int failCount = 0,
  }) {
    if (isGuestMode) {
      return localFlashcardDatasource.saveDeck(
        deckTitle,
        cards,
        imageUrl: imageUrl,
        useImages: useImages,
        scheduledDays: scheduledDays,
        dailyCardCount: dailyCardCount,
        easyCount: easyCount,
        hardCount: hardCount,
        failCount: failCount,
      );
    } else {
      return remoteFlashcardDataSource.saveDeck(
        deckTitle,
        cards,
        imageUrl: imageUrl,
        useImages: useImages,
        scheduledDays: scheduledDays,
        dailyCardCount: dailyCardCount,
        easyCount: easyCount,
        hardCount: hardCount,
        failCount: failCount,
      );
    }
  }

  @override
  Future<void> updateCardProgress(Flashcard card) {
    if (isGuestMode) {
      return localFlashcardDatasource.updateCardProgress(card);
    } else {
      return remoteFlashcardDataSource.updateCardProgress(card);
    }
  }

  @override
  Future<void> updateDeckStats(
    String deckId, {
    int easyIncrement = 0,
    int hardIncrement = 0,
    int failIncrement = 0,
  }) {
    if (isGuestMode) {
      return localFlashcardDatasource.updateDeckStats(
        deckId,
        easyIncrement: easyIncrement,
        hardIncrement: hardIncrement,
        failIncrement: failIncrement,
      );
    } else {
      return remoteFlashcardDataSource.updateDeckStats(
        deckId,
        easyIncrement: easyIncrement,
        hardIncrement: hardIncrement,
        failIncrement: failIncrement,
      );
    }
  }
}
