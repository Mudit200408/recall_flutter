part of 'deck_bloc.dart';

sealed class DeckEvent extends Equatable {
  const DeckEvent();

  @override
  List<Object> get props => [];
}

class LoadDecks extends DeckEvent {}
class CreateDeck extends DeckEvent {
  final String title;
  const CreateDeck({required this.title});
   @override
   List<Object> get props => [title];
}
