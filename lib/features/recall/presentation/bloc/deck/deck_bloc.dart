import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';

part 'deck_event.dart';
part 'deck_state.dart';

class DeckBloc extends Bloc<DeckEvent, DeckState> {
  final FlashcardRepository repository;

  DeckBloc({required this.repository}) : super(DeckInitial()) {
    on<LoadDecks>(_onLoadDecks);
    on<CreateDeck>(_onCreateDeck);
    on<DeleteDeck>(_onDeleteDeck);
  }

  Future<void> _onLoadDecks(LoadDecks event, Emitter<DeckState> emit) async {
    emit(DeckLoading());
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
            final difference = now.difference(lastGenerated).inHours;
            // Simple check: if more than 20 hours have passed since last generation
            if (difference >= 20) {
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
        event.useImages,
      );

      String? deckImageUrl;

      // Save the result to Firestore
      await repository.saveDeck(
        event.title,
        cards,
        imageUrl: deckImageUrl,
        useImages: event.useImages,
        topic: event.title, // Use title as topic
        scheduledDays: event.duration,
        dailyCardCount: event.count,
        easyCount: 0,
        hardCount: 0,
        failCount: 0,
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
