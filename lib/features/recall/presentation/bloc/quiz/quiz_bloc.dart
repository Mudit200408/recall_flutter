import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
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
        ),
      );
    }
  }

  FutureOr<void> _onRateCard(RateCard event, Emitter<QuizState> emit) async {
    if (state is QuizActive) {
      final currentState = state as QuizActive;
      final currentCard = currentState.currentCard;

      // 1: Run the algo (Sync)
      final updateCard = _algo.calculateNextReview(currentCard, event.rating);

      // 2: Update Stats (Sync)
      int easy = currentState.easyCount;
      int hard = currentState.hardCount;

      int easyIncrement = 0;
      int hardIncrement = 0;

      if (event.rating == 5) {
        easy++;
        easyIncrement = 1;
      } else if (event.rating == 3) {
        hard++;
        hardIncrement = 1;
      }

      // 3: Calculate the next state (Sync)
      final nextList = List<Flashcard>.from(currentState.remainingCards)
        ..removeAt(0);

      // 4: EMIT NEW STATE IMMEDIATELY (Optimistic UI)
      if (nextList.isEmpty) {
        // Calculate deletion status
        final bool shouldDelete =
            currentState.deck.daysGenerated >= currentState.deck.scheduledDays;

        emit(
          QuizFinished(
            deck: currentState.deck,
            easyCount: easy,
            hardCount: hard,
            isDeckDeleted: shouldDelete,
          ),
        );

        // 5: Perform DB Operations (Async)
        try {
          await Future.wait([
            repository.updateCardProgress(updateCard),
            repository.updateDeckStats(
              currentState.deck.id,
              easyIncrement: easyIncrement,
              hardIncrement: hardIncrement,
            ),
            repository.markDeckPlayed(currentState.deck.id),
          ]);

          // Handle Deletion
          if (shouldDelete) {
            await repository.deleteDeck(currentState.deck.id);
          } else {
            // Only schedule reminder if NOT deleted
            final tomorrow = DateTime.now().add(const Duration(days: 1));
            notificationService.scheduleStudyReminder(
              tomorrow,
              deckTitle: currentState.deck.title,
            );
          }
        } catch (e) {
          // If DB fails after we showed Finished, we might want to log it.
          // Reverting state is tricky here as user thinks they are done.
          // For now, we assume retry/sync mechanisms or just log.
          debugPrint("Error saving quiz progress: $e");
        }
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
          ),
        );

        // 5: Perform DB Operations (Async for intermediate cards)
        try {
          await Future.wait([
            repository.updateCardProgress(updateCard),
            repository.updateDeckStats(
              currentState.deck.id,
              easyIncrement: easyIncrement,
              hardIncrement: hardIncrement,
            ),
          ]);
        } catch (e) {
          debugPrint("Error saving card progress: $e");
        }
      }
    }
  }
}
