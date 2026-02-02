import 'package:equatable/equatable.dart';

class Deck extends Equatable {
  final String id;
  final String title;
  final int cardCount;
  final String? imageUrl;
  final bool useImages;
  final String topic;
  final int scheduledDays;
  final int daysGenerated;
  final DateTime? lastGeneratedDate;
  final int dailyCardCount;
  final int easyCount;
  final int hardCount;
  final int failCount;

  const Deck({
    required this.id,
    required this.title,
    required this.cardCount,
    this.imageUrl,
    this.useImages = false,
    this.topic = '',
    this.scheduledDays = 0,
    this.daysGenerated = 0,
    this.lastGeneratedDate,
    this.dailyCardCount = 0,
    this.easyCount = 0,
    this.hardCount = 0,
    this.failCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    cardCount,
    imageUrl,
    useImages,
    topic,
    scheduledDays,
    daysGenerated,
    lastGeneratedDate,
    dailyCardCount,
    easyCount,
    hardCount,
    failCount,
  ];
}
