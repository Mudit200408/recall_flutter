import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';

part 'deck_event.dart';
part 'deck_state.dart';

class DeckAction {
  final String deckId;
  final DeckActionType type;
  final int? skippedDaysIncrement;

  DeckAction({
    required this.deckId,
    required this.type,
    this.skippedDaysIncrement,
  });
}

enum DeckActionType { delete, generate, registerSkip }

List<DeckAction> _analyzeDeckActions(List<Deck> decks) {
  final now = DateTime.now();
  final actions = <DeckAction>[];

  for (final deck in decks) {
    // Check for Auto-Delete (Duration + 1 day)
    if (deck.daysGenerated >= deck.scheduledDays) {
      final lastGenerated = deck.lastGeneratedDate;
      if (lastGenerated != null) {
        final difference = now.difference(lastGenerated).inDays;
        if (difference >= 1) {
          actions.add(DeckAction(deckId: deck.id, type: DeckActionType.delete));
          continue;
        }
      }
    }

    // Skip/Generation check — runs for any deck with a lastGeneratedDate
    final lastGenerated = deck.lastGeneratedDate;
    if (lastGenerated != null) {
      final differenceInHours = now.difference(lastGenerated).inHours;
      if (differenceInHours >= 20) {
        // Check if user has played the latest batch
        final hasPlayedLatestBatch =
            deck.lastPlayedDate != null &&
            deck.lastPlayedDate!.isAfter(lastGenerated);

        if (hasPlayedLatestBatch) {
          // User played — check cooldown + remaining days before generating
          final hoursSincePlayed = now.difference(deck.lastPlayedDate!).inHours;

          if (hoursSincePlayed >= 20 &&
              deck.scheduledDays > deck.daysGenerated) {
            // Cooldown met + more days to generate → generate next batch
            actions.add(
              DeckAction(deckId: deck.id, type: DeckActionType.generate),
            );
            break; // Break to reload fresh data before checking next deck
          }
          // else: just played (cooldown pending), or all days generated
        } else {
          // User hasn't played → register skipped days
          // If we're past the threshold and user hasn't played, that's at least 1 skip
          final calculated = (differenceInHours / 24).floor();
          final newSkippedDays = calculated < 1 ? 1 : calculated;
          if (newSkippedDays > deck.skippedDays) {
            actions.add(
              DeckAction(
                deckId: deck.id,
                type: DeckActionType.registerSkip,
                skippedDaysIncrement: newSkippedDays - deck.skippedDays,
              ),
            );
          }
        }
      }
    }
  }
  return actions;
}

class DeckBloc extends Bloc<DeckEvent, DeckState> {
  final FlashcardRepository repository;
  final NotificationService notificationService;
  final bool isGuest;
  bool _isGenerating = false; // Guard against concurrent generation
  String? _generatingDeckId;

  DeckBloc({
    required this.repository,
    required this.notificationService,
    required this.isGuest,
  }) : super(DeckInitial()) {
    on<LoadDecks>(_onLoadDecks);
    on<CreateDeck>(_onCreateDeck);
    on<DeleteDeck>(_onDeleteDeck);
  }

  Future<void> _onLoadDecks(LoadDecks event, Emitter<DeckState> emit) async {
    if (!isGuest) {
      emit(DeckLoading());
    }
    try {
      final decks = await repository.getDecks();
      emit(DeckLoaded(decks: decks, generatingDeckId: _generatingDeckId));

      // Skip generation checks if already generating
      if (_isGenerating) return;

      final actions = await compute(_analyzeDeckActions, decks);
      // Check for daily generation updates
      bool needsReload = false;
      for (final action in actions) {
        switch (action.type) {
          case DeckActionType.delete:
            final deckToDelete = decks.firstWhere((d) => d.id == action.deckId);
            await notificationService.cancelNotification(deckToDelete.title);
            await repository.deleteDeck(action.deckId);
            needsReload = true;
            break;
          case DeckActionType.generate:
            _isGenerating = true;
            _generatingDeckId = action.deckId;
            try {
              emit(
                DeckLoaded(decks: decks, generatingDeckId: _generatingDeckId),
              );

              final deck = decks.firstWhere((d) => d.id == action.deckId);
              await repository.generateMoreCards(deck);
              // notificationService.notifyNewDeckReady(deck.title);
            } finally {
              _isGenerating = false;
              _generatingDeckId = null;
            }
            needsReload = true;
            break;
          case DeckActionType.registerSkip:
            // final skippedDeck = decks.firstWhere((d) => d.id == action.deckId);
            await repository.registerSkippedDay(
              action.deckId,
              action.skippedDaysIncrement!,
            );
            // notificationService.notifySkippedDay(
            //   skippedDeck.title,
            //   action.skippedDaysIncrement!,
            // );
            needsReload = true;
            break;
        }
      }

      // Reload with fresh data if anything changed
      if (needsReload && !isClosed) {
        add(LoadDecks());
      }
    } catch (e) {
      emit(DeckError(message: "Failed to load decks: $e"));
    }
  }

  Future<void> _onCreateDeck(CreateDeck event, Emitter<DeckState> emit) async {
    emit(DeckLoading());
    try {
      // Generate flash cards from AI using the title
      final cards = await repository.generateFlashCards(
        event.title,
        event.count,
        event.difficultyLevel,
      );

      String? deckImageUrl;

      // Save the result to Firestore
      await repository.saveDeck(
        event.title,
        event.difficultyLevel,
        cards,
        imageUrl: deckImageUrl,
        useImages: event.useImages,
        scheduledDays: event.duration,
        dailyCardCount: event.count,
        easyCount: 0,
        hardCount: 0,
      );

      // Refresh the list to show the new deck
      add(LoadDecks());
    } catch (e) {
      emit(DeckError(message: "Failed to create deck: $e"));
    }
  }

  FutureOr<void> _onDeleteDeck(
    DeleteDeck event,
    Emitter<DeckState> emit,
  ) async {
    if (state is DeckLoaded) {
      try {
        final deck = (state as DeckLoaded).decks.firstWhere(
          (d) => d.id == event.deckId,
        );
        await notificationService.cancelNotification(deck.title);
      } catch (_) {
        // Deck not found in current state, proceed anyway
      }
    }
    emit(DeckLoading());
    try {
      await repository.deleteDeck(event.deckId);
      add(LoadDecks());
    } catch (e) {
      emit(DeckError(message: "Failed to delete deck: $e"));
    }
  }
}
