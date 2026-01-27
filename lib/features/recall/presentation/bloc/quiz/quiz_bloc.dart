import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/features/recall/domain/services/spaced_repetition_service.dart';

part 'quiz_event.dart';
part 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final FlashcardRepository repository;
  final SpacedRepetitionService _algo = SpacedRepetitionService();
  final NotificationService notificationService;

  QuizBloc({required this.repository, required this.notificationService}) : super(QuizInitial()) {
    on<StartQuiz>(_onStartQuiz);
    on<FlipCard>(_onFlipCard);
    on<RateCard>(_onRateCard);
  }

  FutureOr<void> _onStartQuiz(StartQuiz event, Emitter<QuizState> emit) async {
    emit(QuizLoading());
    try {
      final cards = await repository.getDueCards(event.deckId);
      if (cards.isEmpty) {
        emit(QuizEmpty());
      } else {
        emit(
          QuizActive(
            currentCard: cards.first,
            remainingCards: cards,
            isFlipped: false,
          ),
        );
      }
    } catch (e) {
      emit(QuizError(message: "Failed to start quiz: $e"));
    }
  }

  FutureOr<void> _onFlipCard(FlipCard event, Emitter<QuizState> emit) {
    if (state is QuizActive) {
      final currentState = state as QuizActive;
      emit(
        QuizActive(
          remainingCards: currentState.remainingCards,
          currentCard: currentState.currentCard,
          isFlipped: true,
        ),
      );
    }
  }

  FutureOr<void> _onRateCard(RateCard event, Emitter<QuizState> emit) async {
    if (state is QuizActive) {
      final currentState = state as QuizActive;
      final currentCard = currentState.currentCard;

      // 1: Run the algo
      final updateCard = _algo.calculateNextReview(currentCard, event.rating);

      // 2: Save to DB
      repository.updateCardProgress(updateCard);

      // 3: Calculate the next state
      final nextList = List<Flashcard>.from(currentState.remainingCards)
        ..removeAt(0);

      if (nextList.isEmpty) {
        // Calculate the next due date
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        
        // Schedule Notification
        notificationService.scheduleStudyReminder(tomorrow);
        emit(QuizFinished());
      } else {
        emit(
          QuizActive(
            remainingCards: nextList,
            currentCard: nextList.first,
            isFlipped: false,
          ),
        );
      }
    }
  }
}
