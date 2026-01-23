part of 'quiz_bloc.dart';

sealed class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object> get props => [];
}

class StartQuiz extends QuizEvent {
  final String deckId;
  const StartQuiz({required this.deckId});
}

class FlipCard extends QuizEvent{}

class RateCard extends QuizEvent {
  final int rating;
  const RateCard({required this.rating});
}