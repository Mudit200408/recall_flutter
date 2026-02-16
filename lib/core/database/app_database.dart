import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';
import 'dart:io';

part 'app_database.g.dart';

@DriftDatabase(tables: [Decks, Flashcards])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(decks, decks.lastGeneratedDate);
        }
      },
    );
  }

  // Read Operations
  Future<List<Deck>> getAllDecks() => select(decks).get();

  Future<List<Flashcard>> getDueCardsForDeck(String deckId) {
    final now = DateTime.now();
    return (select(flashcards)
          ..where((tbl) => tbl.deckId.equals(deckId))
          ..where((tbl) => tbl.dueDate.isSmallerThanValue(now)))
        .get();
  }

  Future<Deck?> getDeckById(String deckId) {
    return (select(decks)..where((t) => t.id.equals(deckId))).getSingleOrNull();
  }

  // WRITE OPERATIONS
  Future<void> insertDeck(Deck deck) =>
      into(decks).insert(deck, mode: InsertMode.replace);
  Future<void> insertCard(Flashcard card) =>
      into(flashcards).insert(card, mode: InsertMode.replace);

  Future<void> deleteDeck(String id) =>
      (delete(decks)..where((t) => t.id.equals(id))).go();

  Future<void> updateCard(Flashcard card) => update(flashcards).replace(card);
}

// Opening the connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
