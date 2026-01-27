import 'package:equatable/equatable.dart';

class Deck extends Equatable {
  final String id;
  final String title;
  final int cardCount;
  final String? imageUrl;

  const Deck({
    required this.id,
    required this.title,
    required this.cardCount,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, title, cardCount, imageUrl];
}
