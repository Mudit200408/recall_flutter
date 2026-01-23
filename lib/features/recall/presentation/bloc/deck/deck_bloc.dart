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
     final cards = await repository.generateFlashCards(event.title);

      // Save the result to Firestore
      await repository.saveDeck(event.title, cards);

      // Refresh the list to show the new deck
      add(LoadDecks());

    } catch (e) {
      emit(DeckError(message: "Failed to create deck: $e"));
    }
  }
}
