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

      // Check for daily generation updates
      for (final deck in decks) {
        // Check for Auto-Delete (Duration + 1 day)
        if (deck.daysGenerated >= deck.scheduledDays) {
          final lastGenerated = deck.lastGeneratedDate;
          if (lastGenerated != null) {
            final now = DateTime.now();
            final difference = now.difference(lastGenerated).inDays;
            if (difference >= 1) {
              repository.deleteDeck(deck.id).then((_) {
                if (!isClosed) add(LoadDecks());
              });
              continue; // Skip generation check if deleting
            }
          }
        }

        if (deck.scheduledDays > deck.daysGenerated) {
          final lastGenerated = deck.lastGeneratedDate;
          if (lastGenerated != null) {
            final now = DateTime.now();
            final differenceInHours = now.difference(lastGenerated).inHours;

            // Skipped Day Logic (> 48h means at least 1 day missed)
            if (differenceInHours >= 48) {
              // daysGenerated increments by 1 every 24h roughly.
              // If 48h passed, we missed 1 trigger.
              // If 72h passed, we missed 2 triggers.
              // So missed = (hours / 24).floor() - 1?
              // No, simpler:
              // 24h = 0 missed (normal trigger)
              // 48h = 1 missed
              // 72h = 2 missed
              final daysSkipped = (differenceInHours / 24).floor() - 1;
              if (daysSkipped > 0) {
                repository.registerSkippedDay(deck.id, daysSkipped);
              }
            }

            // Simple check: if more than 20 hours have passed since last generation
            if (differenceInHours >= 20) {
              repository.generateMoreCards(deck).then((_) {
                if (!isClosed) {
                  add(LoadDecks());
                }
              });
            }
          }
        }
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
