part of 'deck_bloc.dart';

sealed class DeckState extends Equatable {
  const DeckState();

  @override
  List<Object?> get props => [];
}

class DeckInitial extends DeckState {}

class DeckLoading extends DeckState {}

class DeckLoaded extends DeckState {
  final List<Deck> decks;
  final String? generatingDeckId;
  const DeckLoaded({required this.decks, this.generatingDeckId});
  @override
  List<Object?> get props => [decks, generatingDeckId];
}

class DeckError extends DeckState {
  final String message;
  const DeckError({required this.message});
  @override
  List<Object?> get props => [message];
}
