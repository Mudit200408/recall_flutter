part of 'deck_bloc.dart';

sealed class DeckEvent extends Equatable {
  const DeckEvent();

  @override
  List<Object> get props => [];
}

class LoadDecks extends DeckEvent {}
class CreateDeck extends DeckEvent {
  final String title;
  final int count;
  const CreateDeck({required this.title, required this.count});
   @override
   List<Object> get props => [title];
}

class DeleteDeck extends DeckEvent {
  final String deckId;
  const DeleteDeck({required this.deckId});
   @override
   List<Object> get props => [deckId];
}
