part of 'quiz_bloc.dart';

sealed class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object> get props => [];
}

final class QuizInitial extends QuizState {}

class QuizLoading extends QuizState {}

class QuizActive extends QuizState {
  final List<Flashcard> remainingCards;
  final Flashcard currentCard;
  final bool isFlipped;
  final int totalCards;
  final Deck deck;

  const QuizActive({
    required this.remainingCards,
    required this.currentCard,
    required this.isFlipped,
    required this.totalCards,
    required this.deck,
  });

  @override
  List<Object> get props => [
    remainingCards,
    currentCard,
    isFlipped,
    totalCards,
    deck,
  ];
}

class QuizEmpty extends QuizState {}

class QuizFinished extends QuizState {
  final Deck deck;
  const QuizFinished({required this.deck});

  @override
  List<Object> get props => [deck];
}

class QuizError extends QuizState {
  final String message;
  const QuizError({required this.message});

  @override
  List<Object> get props => [message];
}
