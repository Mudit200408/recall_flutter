import 'package:drift/drift.dart';
import 'package:recall/core/database/app_database.dart' as db;
import 'package:recall/features/recall/data/datasource/flashcard_datasource.dart';
import 'package:recall/features/recall/data/models/flashcard_model.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';
import 'package:uuid/uuid.dart';

class LocalFlashcardDatasource implements FlashcardDataSource {
  final db.AppDatabase database;

  LocalFlashcardDatasource({required this.database});

  @override
  Future<List<Flashcard>> getDueCards(String deckId) async {
    final dbCards = await database.getDueCardsForDeck(deckId);

    return dbCards
        .map(
          (c) => FlashcardModel(
            id: c.id,
            deckId: c.deckId,
            front: c.front,
            back: c.back,
            interval: c.interval,
            repetitions: c.repetitions,
            easeFactor: c.easeFactor,
            dueDate: c.dueDate,
          ),
        )
        .toList();
  }

  @override
  Future<List<Deck>> getDecks() async {
    final dbDecks = await database.getAllDecks();

    return dbDecks
        .map(
          (d) => Deck(
            id: d.id,
            title: d.title,
            scheduledDays: d.scheduledDays,
            daysGenerated: d.daysGenerated,
            lastGeneratedDate: d.lastGeneratedDate,
            cardCount: d.cardCount,
            dailyCardCount: d.dailyCardCount,
            useImages: d.useImages,
            easyCount: d.easyCount,
            hardCount: d.hardCount,
            failCount: d.failCount,
            skippedDays: d.skippedDays,
          ),
        )
        .toList();
  }

  @override
  Future<void> addCards(String deckId, List<Flashcard> cards) async {
    for (final card in cards) {
      await database.insertCard(
        db.Flashcard(
          id: const Uuid().v4(),
          deckId: deckId,
          front: card.front,
          back: card.back,
          interval: 0,
          repetitions: 0,
          easeFactor: 2.5,
          dueDate: DateTime.now(),
        ),
      );
    }

    // Update deck generation stats
    final deck = await database.getDeckById(deckId);
    if (deck != null) {
      await database.insertDeck(
        deck.copyWith(
          cardCount: deck.cardCount + cards.length,
          daysGenerated: deck.daysGenerated + 1,
          lastGeneratedDate: Value(DateTime.now()),
        ),
      );
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
  }) async {
    final deckId = const Uuid().v4();
    await database.insertDeck(
      db.Deck(
        id: deckId,
        title: deckTitle,
        scheduledDays: scheduledDays,
        daysGenerated: 1,
        lastGeneratedDate: DateTime.now(),
        cardCount: cards.length,
        dailyCardCount: dailyCardCount,
        useImages: useImages,
        easyCount: easyCount,
        hardCount: hardCount,
        failCount: failCount,
        skippedDays: 0,
      ),
    );
    for (final card in cards) {
      await database.insertCard(
        db.Flashcard(
          id: const Uuid().v4(),
          deckId: deckId,
          front: card.front,
          back: card.back,
          interval: 0,
          repetitions: 0,
          easeFactor: 2.5,
          dueDate: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<void> updateCardProgress(Flashcard card) async {
    await database.updateCard(
      db.Flashcard(
        id: card.id,
        deckId: card.deckId,
        front: card.front,
        back: card.back,
        interval: card.interval,
        repetitions: card.repetitions,
        easeFactor: card.easeFactor,
        dueDate: card.dueDate,
      ),
    );
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    await database.deleteDeck(deckId);
  }

  @override
  Future<void> updateDeckStats(
    String deckId, {
    int easyIncrement = 0,
    int hardIncrement = 0,
    int failIncrement = 0,
  }) async {
    final deck = await database.getDeckById(deckId);
    if (deck != null) {
      await database.insertDeck(
        deck.copyWith(
          easyCount: deck.easyCount + easyIncrement,
          hardCount: deck.hardCount + hardIncrement,
          failCount: deck.failCount + failIncrement,
        ),
      );
    }
  }

  @override
  Future<void> registerSkippedDay(String deckId, int daysSkipped) async {
    final deck = await database.getDeckById(deckId);
    if (deck != null) {
      await database.insertDeck(
        deck.copyWith(skippedDays: deck.skippedDays + daysSkipped),
      );
    }
  }
}
