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
      if (event.useImages) {
        try {
          deckImageUrl = await repository.generateImageForCard(
            "Concept art representing: ${event.title}",
          );
        } catch (e) {
          // Ignore deck image failure
        }
      }

      // Save the result to Firestore
      await repository.saveDeck(event.title, cards, imageUrl: deckImageUrl);

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
