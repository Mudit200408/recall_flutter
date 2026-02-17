import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:recall/features/recall/data/datasource/flashcard_datasource.dart';
import 'package:recall/features/recall/data/models/flashcard_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';
import 'package:recall/features/recall/domain/services/image_generation_service.dart';

import 'package:firebase_storage/firebase_storage.dart';

class RemoteFlashcardDataSource implements FlashcardDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final String userId;
  final http.Client httpClient;
  final String modelId;
  final ImageGenerationService imageService;

  RemoteFlashcardDataSource({
    required this.firestore,
    required this.storage,
    required this.userId,
    required this.httpClient,
    required this.imageService,
    this.modelId = 'arcee-ai/trinity-mini:free',
  });

  @override
  Future<List<Flashcard>> getDueCards(String deckId) async {
    final now = DateTime.now();

    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    return snapshot.docs
        .map((doc) => FlashcardModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> updateCardProgress(Flashcard card) async {
    // 1: Create Model
    final model = FlashcardModel(
      id: card.id,
      deckId: card.deckId,
      front: card.front,
      back: card.back,
      interval: card.interval,
      repetitions: card.repetitions,
      easeFactor: card.easeFactor,
      dueDate: card.dueDate,
    );

    // 2: Direct Update
    await firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(card.deckId)
        .collection('cards')
        .doc(card.id)
        .update(model.toJson());
  }

  @override
  Future<void> saveDeck(
    String deckTitle,
    String difficultyLevel,
    List<Flashcard> cards, {
    String? imageUrl,
    bool useImages = false,
    int scheduledDays = 0,
    int dailyCardCount = 0,
    int easyCount = 0,
    int hardCount = 0,
  }) async {
    // Generate deck image if not provided and enabled
    if (imageUrl == null && useImages) {
      imageUrl = await imageService.generateDeckImage(deckTitle);
    }

    // If image is Base64, upload to storage
    if (imageUrl != null && imageUrl.startsWith('data:image')) {
      try {
        imageUrl = await _uploadImageToStorage(imageUrl, deckTitle);
      } catch (e) {
        debugPrint("Error uploading image: $e");
        // Fallback to null or keep base64? Keeping base64 will crash firestore.
        imageUrl = null;
      }
    }

    // A Writebatch is atomic. All or nothing
    final batch = firestore.batch();

    // 1: Create Deck Reference
    final deckRef = firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(); // Auto-ID

    // 2: Set Deck Data
    batch.set(deckRef, {
      'title': deckTitle,
      'difficultyLevel': difficultyLevel,
      'cardCount': cards.length,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'scheduledDays': scheduledDays,
      'daysGenerated': 1,
      'lastGeneratedDate': FieldValue.serverTimestamp(),
      'dailyCardCount': dailyCardCount,
      'useImages': useImages,
      'easyCount': easyCount,
      'hardCount': hardCount,
      'skippedDays': 0, // Initial value
      'lastPlayedDate': null,
    });

    // 3: Set Cards Data
    // We'll use a list of Futures to process card images in parallel if possible,
    // but sequential is safer for now to avoid rate limits or complexity.
    for (final card in cards) {
      // Create a reference inside a new deck
      final cardRef = deckRef.collection('cards').doc();

      String? cardImageUrl = card.imageUrl;
      if (cardImageUrl != null && cardImageUrl.startsWith('data:image')) {
        try {
          cardImageUrl = await _uploadImageToStorage(
            cardImageUrl,
            '${deckTitle}_card_${card.front}',
          );
        } catch (e) {
          debugPrint("Error uploading card image: $e");
          cardImageUrl = null;
        }
      }

      // We need to assign the new IDs to the card models before saving
      final cardModel = FlashcardModel(
        id: cardRef.id,
        deckId: deckRef.id,
        front: card.front,
        back: card.back,
        interval: 0,
        repetitions: 0,
        easeFactor: 2.5,
        dueDate: DateTime.now(),
        imageUrl: cardImageUrl,
      );
      batch.set(cardRef, cardModel.toJson());
    }

    // 4: Commit Batch
    await batch.commit();
  }

  @override
  Future<List<Deck>> getDecks() async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Deck(
        id: doc.id,
        title: data['title'] ?? 'Untitled',
        difficultyLevel: data['difficultyLevel'] ?? 'easy',
        cardCount: data['cardCount'] ?? 0,
        imageUrl: data['imageUrl'] as String?,
        scheduledDays: data['scheduledDays'] ?? 0,
        daysGenerated: data['daysGenerated'] ?? 0,
        lastGeneratedDate: (data['lastGeneratedDate'] as Timestamp?)?.toDate(),
        dailyCardCount: data['dailyCardCount'] ?? 0,
        useImages: data['useImages'] ?? false,
        easyCount: data['easyCount'] ?? 0,
        hardCount: data['hardCount'] ?? 0,
        skippedDays: data['skippedDays'] ?? 0,
        lastPlayedDate: (data['lastPlayedDate'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<void> addCards(String deckId, List<Flashcard> cards) async {
    final batch = firestore.batch();
    final deckRef = firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId);

    for (final card in cards) {
      final cardRef = deckRef.collection('cards').doc();
      final cardModel = FlashcardModel(
        id: cardRef.id,
        deckId: deckId,
        front: card.front,
        back: card.back,
        interval: 0,
        repetitions: 0,
        easeFactor: 2.5,
        dueDate: DateTime.now(),
        imageUrl: card.imageUrl,
      );
      batch.set(cardRef, cardModel.toJson());
    }

    // Update deck count
    batch.update(deckRef, {
      'cardCount': FieldValue.increment(cards.length),
      'daysGenerated': FieldValue.increment(1),
      'lastGeneratedDate': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    final batch = firestore.batch();
    final deckRef = firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId);

    // 1. Get Deck Data to find image URL
    final deckSnapshot = await deckRef.get();
    final deckData = deckSnapshot.data();
    if (deckData != null && deckData['imageUrl'] != null) {
      final imageUrl = deckData['imageUrl'] as String;
      if (imageUrl.startsWith('https://firebasestorage')) {
        try {
          // Extract path or ref from URL?
          // Actually, getting ref from URL is easy
          await storage.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint("Error deleting deck image: $e");
        }
      }
    }

    // 2. Get all the cards in the deck
    final cardSnapshot = await deckRef.collection('cards').get();

    // 3. Delete all the cards and their images
    for (var doc in cardSnapshot.docs) {
      final data = doc.data();
      if (data['imageUrl'] != null) {
        final cardImageUrl = data['imageUrl'] as String;
        if (cardImageUrl.startsWith('https://firebasestorage')) {
          try {
            await storage.refFromURL(cardImageUrl).delete();
          } catch (e) {
            debugPrint("Error deleting card image: $e");
          }
        }
      }
      batch.delete(doc.reference);
    }
    batch.delete(deckRef);
    await batch.commit();
  }

  Future<String> _uploadImageToStorage(String base64Image, String title) async {
    try {
      // 1. Parse Base64
      // Format: "data:image/png;base64,....."
      final split = base64Image.split(',');
      if (split.length != 2) return base64Image; // Not valid format

      final data = base64Decode(split.last);

      // 2. Create Reference
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.png';
      final ref = storage.ref().child('users/$userId/deck_images/$filename');

      // 3. Upload
      final metadata = SettableMetadata(contentType: 'image/png');
      await ref.putData(data, metadata);

      // 4. Get URL
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Storage Upload Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateDeckStats(
    String deckId, {
    int easyIncrement = 0,
    int hardIncrement = 0,
  }) async {
    final deckRef = firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId);

    await deckRef.update({
      'easyCount': FieldValue.increment(easyIncrement),
      'hardCount': FieldValue.increment(hardIncrement),
    });
  }

  @override
  Future<void> registerSkippedDay(String deckId, int daysSkipped) async {
    final deckRef = firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId);

    // Only increment skippedDays counter, do NOT extend deadline (scheduledDays)
    await deckRef.update({'skippedDays': FieldValue.increment(daysSkipped)});
  }

  @override
  Future<void> markDeckPlayed(String deckId) async {
    final deckRef = firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId);

    await deckRef.update({
      'lastPlayedDate': FieldValue.serverTimestamp(),
      'skippedDays': 0,
    });
  }
}
