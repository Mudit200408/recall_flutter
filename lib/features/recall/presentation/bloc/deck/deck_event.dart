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
  final String difficultyLevel;
  final bool useImages;
  final int duration;
  const CreateDeck({
    required this.title,
    required this.count,
    required this.difficultyLevel,
    required this.useImages,
    this.duration = 0,
  });
  @override
  List<Object> get props => [title, count, difficultyLevel, useImages, duration];
}

class DeleteDeck extends DeckEvent {
  final String deckId;
  const DeleteDeck({required this.deckId});
  @override
  List<Object> get props => [deckId];
}
