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

  const QuizActive({
    required this.remainingCards,
    required this.currentCard,
    required this.isFlipped,
  });

  @override
  List<Object> get props => [remainingCards, currentCard, isFlipped];
}

class QuizEmpty extends QuizState {}

class QuizFinished extends QuizState {}

class QuizError extends QuizState {
final String message;
const QuizError({required this.message});

@override
List<Object> get props => [message];
}