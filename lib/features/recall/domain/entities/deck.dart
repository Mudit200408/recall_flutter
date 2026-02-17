import 'package:equatable/equatable.dart';

class Deck extends Equatable {
  final String id;
  final String title;
  final int cardCount;
  final String? imageUrl;
  final bool useImages;
  final int scheduledDays;
  final int daysGenerated;
  final DateTime? lastGeneratedDate;
  final int dailyCardCount;
  final int easyCount;
  final int hardCount;
  final String difficultyLevel;
  final int skippedDays;
  final DateTime? lastPlayedDate;

  const Deck({
    required this.id,
    required this.title,
    required this.difficultyLevel,
    required this.cardCount,
    this.imageUrl,
    this.useImages = false,
    this.scheduledDays = 0,
    this.daysGenerated = 0,
    this.lastGeneratedDate,
    this.dailyCardCount = 0,
    this.easyCount = 0,
    this.hardCount = 0,

    this.skippedDays = 0,
    this.lastPlayedDate,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    difficultyLevel,
    cardCount,
    imageUrl,
    useImages,
    scheduledDays,
    daysGenerated,
    lastGeneratedDate,
    dailyCardCount,
    easyCount,
    hardCount,
    skippedDays,
    lastPlayedDate,
  ];
}
