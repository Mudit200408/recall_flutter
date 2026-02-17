import 'package:drift/drift.dart';

class Decks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get difficultyLevel => text()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get scheduledDays => integer().withDefault(const Constant(0))();
  IntColumn get daysGenerated => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastGeneratedDate => dateTime().nullable()();
  IntColumn get cardCount => integer()();
  IntColumn get dailyCardCount => integer()();
  BoolColumn get useImages => boolean().withDefault(const Constant(false))();

  // Stats
  IntColumn get easyCount => integer().withDefault(const Constant(0))();
  IntColumn get hardCount => integer().withDefault(const Constant(0))();
  IntColumn get skippedDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Flashcards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId =>
      text().references(Decks, #id, onDelete: KeyAction.cascade)();
  TextColumn get front => text()();
  TextColumn get back => text()();

  // Spaced Repetition
  IntColumn get interval => integer()();
  IntColumn get repetitions => integer()();
  RealColumn get easeFactor => real()();
  DateTimeColumn get dueDate => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
