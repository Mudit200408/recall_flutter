import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/features/recall/domain/services/spaced_repetition_service.dart';

part 'quiz_event.dart';
part 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final FlashcardRepository repository;
  final SpacedRepetitionService _algo = SpacedRepetitionService();
  final NotificationService notificationService;

  QuizBloc({required this.repository, required this.notificationService})
    : super(QuizInitial()) {
    on<StartQuiz>(_onStartQuiz);
    on<FlipCard>(_onFlipCard);
    on<RateCard>(_onRateCard);
  }

  FutureOr<void> _onStartQuiz(StartQuiz event, Emitter<QuizState> emit) async {
    emit(QuizLoading());
    try {
      final cards = await repository.getDueCards(event.deck.id);
      if (cards.isEmpty) {
        emit(QuizEmpty(deck: event.deck));
      } else {
        emit(
          QuizActive(
            currentCard: cards.first,
            remainingCards: cards,
            isFlipped: false,
            totalCards: cards.length,
            deck: event.deck,
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
          totalCards: currentState.totalCards,
          deck: currentState.deck,
          easyCount: currentState.easyCount,
          hardCount: currentState.hardCount,
          failCount: currentState.failCount,
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
      await repository.updateCardProgress(updateCard);

      // 2.5: Update Stats
      int easy = currentState.easyCount;
      int hard = currentState.hardCount;
      int fail = currentState.failCount;

      int easyIncrement = 0;
      int hardIncrement = 0;
      int failIncrement = 0;

      if (event.rating == 5) {
        easy++;
        easyIncrement = 1;
      } else if (event.rating == 3) {
        hard++;
        hardIncrement = 1;
      } else if (event.rating == 1) {
        fail++;
        failIncrement = 1;
      }

      // Update Deck Stats in Repo
      await repository.updateDeckStats(
        currentState.deck.id,
        easyIncrement: easyIncrement,
        hardIncrement: hardIncrement,
        failIncrement: failIncrement,
      );

      // 3: Calculate the next state
      final nextList = List<Flashcard>.from(currentState.remainingCards)
        ..removeAt(0);

      if (nextList.isEmpty) {
        // Calculate the next due date
        final tomorrow = DateTime.now().add(const Duration(days: 1));

        // Schedule Notification
        // Check for immediate deletion criteria
        bool isDeleted = false;
        if (currentState.deck.daysGenerated >=
            currentState.deck.scheduledDays) {
          try {
            await repository.deleteDeck(currentState.deck.id);
            isDeleted = true;
          } catch (e) {
            // Log error but continue flow
            // debugPrint("Failed to delete deck: $e");
          }
        } else {
          // Only schedule reminder if NOT deleted
          notificationService.scheduleStudyReminder(tomorrow);
        }

        emit(
          QuizFinished(
            deck: currentState.deck,
            easyCount: easy,
            hardCount: hard,
            failCount: fail,
            isDeckDeleted: isDeleted,
          ),
        );
      } else {
        emit(
          QuizActive(
            remainingCards: nextList,
            currentCard: nextList.first,
            isFlipped: false,
            totalCards: currentState.totalCards,
            deck: currentState.deck,
            easyCount: easy,
            hardCount: hard,
            failCount: fail,
          ),
        );
      }
    }
  }
}
