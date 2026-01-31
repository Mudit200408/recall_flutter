part of 'quiz_bloc.dart';

sealed class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object> get props => [];
}

class StartQuiz extends QuizEvent {
  final Deck deck;
  const StartQuiz({required this.deck});
}

class FlipCard extends QuizEvent {}

class RateCard extends QuizEvent {
  final int rating;
  const RateCard({required this.rating});
}
