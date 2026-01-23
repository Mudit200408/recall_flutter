import 'package:equatable/equatable.dart';

class Flashcard extends Equatable {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final int interval;      // Days
  final int repetitions;   // Consecutive correct answers
  final double easeFactor; // Multiplier (Standard start is 2.5)
  final DateTime dueDate;

  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.interval,
    required this.repetitions,
    required this.easeFactor,
    required this.dueDate,
  });

  // Factory for creating a BRAND NEW card with default stats
  factory Flashcard.newCard({
    required String id,
    required String deckId,
    required String front,
    required String back,
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: front,
      back: back,
      interval: 0,
      repetitions: 0,
      easeFactor: 2.5, // Standard SM-2 starting value
      dueDate: DateTime.now(),
    );
  }

  // Essential for updating immutable objects
  Flashcard copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    int? interval,
    int? repetitions,
    double? easeFactor,
    DateTime? dueDate,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deckId,
        front,
        back,
        interval,
        repetitions,
        easeFactor,
        dueDate,
      ];
}