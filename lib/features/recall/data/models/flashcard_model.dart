import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';

class FlashcardModel extends Flashcard {
  const FlashcardModel({
    required super.id,
    required super.deckId,
    required super.front,
    required super.back,
    required super.interval,
    required super.repetitions,
    required super.easeFactor,
    required super.dueDate,
    super.imageUrl,
  });

  // 1: From JSON
  // Convert a Map into Dart Object
  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String,
      deckId: json['deckId'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      interval: (json['interval'] as num).toInt(),
      repetitions: (json['repetitions'] as num).toInt(),
      easeFactor: (json['easeFactor'] as num).toDouble(),
      dueDate: json['dueDate'] is Timestamp
          ? (json['dueDate'] as Timestamp).toDate()
          : DateTime.parse(json['dueDate'] as String),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  // 2: From Firestor Snapshot
  factory FlashcardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FlashcardModel(
      id: doc.id,
      deckId: data['deckId'] ?? '',
      front: data['front'] ?? '',
      back: data['back'] ?? '',
      interval: (data['interval'] ?? 0) as int,
      repetitions: (data['repetitions'] ?? 0) as int,
      easeFactor: (data['easeFactor'] ?? 2.5).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  // 3: TO JSON
  // Convert Dart Object into Map to send to Firestore
  Map<String, dynamic> toJson() {
    return {
      'deckId': deckId,
      'front': front,
      'back': back,
      'interval': interval,
      'repetitions': repetitions,
      'easeFactor': easeFactor,
      'dueDate': Timestamp.fromDate(
        dueDate,
      ), // Convert Dart datetime to firebase timestamp
      'imageUrl': imageUrl,
    };
  }
}
