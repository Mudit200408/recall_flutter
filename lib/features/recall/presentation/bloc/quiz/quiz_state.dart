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
  final int easyCount;
  final int hardCount;

  const QuizActive({
    required this.remainingCards,
    required this.currentCard,
    required this.isFlipped,
    required this.totalCards,
    required this.deck,
    this.easyCount = 0,
    this.hardCount = 0,
  });

  @override
  List<Object> get props => [
    remainingCards,
    currentCard,
    isFlipped,
    totalCards,
    deck,
    easyCount,
    hardCount,
  ];
}

class QuizEmpty extends QuizState {
  final Deck deck;
  const QuizEmpty({required this.deck});

  @override
  List<Object> get props => [deck];
}

class QuizFinished extends QuizState {
  final Deck deck;
  final int easyCount;
  final int hardCount;
  final bool isDeckDeleted;

  const QuizFinished({
    required this.deck,
    required this.easyCount,
    required this.hardCount,
    this.isDeckDeleted = false,
  });

  @override
  List<Object> get props => [deck, easyCount, hardCount, isDeckDeleted];
}

class QuizError extends QuizState {
  final String message;
  const QuizError({required this.message});

  @override
  List<Object> get props => [message];
}
