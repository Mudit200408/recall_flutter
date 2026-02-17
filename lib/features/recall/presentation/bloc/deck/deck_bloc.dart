import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';

part 'deck_event.dart';
part 'deck_state.dart';

class DeckBloc extends Bloc<DeckEvent, DeckState> {
  final FlashcardRepository repository;
  final bool isGuest;
  bool _isGenerating = false; // Guard against concurrent generation

  DeckBloc({required this.repository, required this.isGuest})
    : super(DeckInitial()) {
    on<LoadDecks>(_onLoadDecks);
    on<CreateDeck>(_onCreateDeck);
    on<DeleteDeck>(_onDeleteDeck);
  }

  Future<void> _onLoadDecks(LoadDecks event, Emitter<DeckState> emit) async {
    if (!isGuest) {
      emit(DeckLoading());
    }
    try {
      final decks = await repository.getDecks();
      emit(DeckLoaded(decks: decks));

      // Skip generation checks if already generating
      if (_isGenerating) return;

      // Check for daily generation updates
      bool needsReload = false;
      for (final deck in decks) {
        // Check for Auto-Delete (Duration + 1 day)
        if (deck.daysGenerated >= deck.scheduledDays) {
          final lastGenerated = deck.lastGeneratedDate;
          if (lastGenerated != null) {
            final now = DateTime.now();
            final difference = now.difference(lastGenerated).inDays;
            if (difference >= 1) {
              await repository.deleteDeck(deck.id);
              needsReload = true;
              continue;
            }
          }
        }

        // Skip/Generation check — runs for any deck with a lastGeneratedDate
        final lastGenerated = deck.lastGeneratedDate;
        if (lastGenerated != null) {
          final now = DateTime.now();
          final differenceInHours = now.difference(lastGenerated).inHours;

          final differenceInMinutes = now.difference(lastGenerated).inMinutes;
          // TODO: Revert to production threshold before release
          // Production: if (differenceInHours >= 20)
          if (differenceInMinutes >= 1) {
            // Check if user has played the latest batch
            final hasPlayedLatestBatch =
                deck.lastPlayedDate != null &&
                deck.lastPlayedDate!.isAfter(lastGenerated);

            if (hasPlayedLatestBatch) {
              // User played — check cooldown + remaining days before generating
              // TODO: Revert to production threshold before release
              // Production: final hoursSincePlayed = now.difference(deck.lastPlayedDate!).inHours;
              // Production: if (hoursSincePlayed >= 20)
              final minutesSincePlayed = now
                  .difference(deck.lastPlayedDate!)
                  .inMinutes;
              if (minutesSincePlayed >= 1 &&
                  deck.scheduledDays > deck.daysGenerated) {
                // Cooldown met + more days to generate → generate next batch
                _isGenerating = true;
                try {
                  await repository.generateMoreCards(deck);
                } finally {
                  _isGenerating = false;
                }
                needsReload = true;
                break; // Break to reload fresh data before checking next deck
              }
              // else: just played (cooldown pending), or all days generated
            } else {
              // User hasn't played → register skipped days
              // If we're past the threshold and user hasn't played, that's at least 1 skip
              // TODO: Revert to production threshold before release
              // Production: final calculated = (differenceInHours / 24).floor();
              final calculated = (differenceInMinutes / 2).floor();
              final newSkippedDays = calculated < 1 ? 1 : calculated;
              if (newSkippedDays > deck.skippedDays) {
                await repository.registerSkippedDay(
                  deck.id,
                  newSkippedDays - deck.skippedDays,
                );
                needsReload = true;
              }
            }
          }
        }
      }

      // Reload with fresh data if anything changed
      if (needsReload && !isClosed) {
        add(LoadDecks());
      }
    } catch (e) {
      emit(DeckError(message: "Failed to load decks: $e"));
    }
  }

  Future<void> _onCreateDeck(CreateDeck event, Emitter<DeckState> emit) async {
    emit(DeckLoading());
    try {
      // Generate flash cards from AI using the title
      final cards = await repository.generateFlashCards(
        event.title,
        event.count,
        event.difficultyLevel,
      );

      String? deckImageUrl;

      // Save the result to Firestore
      await repository.saveDeck(
        event.title,
        event.difficultyLevel,
        cards,
        imageUrl: deckImageUrl,
        useImages: event.useImages,
        scheduledDays: event.duration,
        dailyCardCount: event.count,
        easyCount: 0,
        hardCount: 0,
      );

      // Refresh the list to show the new deck
      add(LoadDecks());
    } catch (e) {
      emit(DeckError(message: "Failed to create deck: $e"));
    }
  }

  FutureOr<void> _onDeleteDeck(
    DeleteDeck event,
    Emitter<DeckState> emit,
  ) async {
    emit(DeckLoading());
    try {
      await repository.deleteDeck(event.deckId);
      add(LoadDecks());
    } catch (e) {
      emit(DeckError(message: "Failed to delete deck: $e"));
    }
  }
}
