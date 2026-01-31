import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_ai/firebase_ai.dart';
import 'package:recall/features/recall/data/models/flashcard_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/features/recall/domain/services/image_generation_service.dart';

import 'package:firebase_storage/firebase_storage.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final String userId;
  final http.Client httpClient;
  final String modelId;
  final ImageGenerationService imageService;

  FlashcardRepositoryImpl({
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
    List<Flashcard> cards, {
    String? imageUrl,
  }) async {
    // Generate deck image if not provided
    // Generate deck image if not provided
    imageUrl ??= await imageService.generateDeckImage(deckTitle);

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
      'cardCount': cards.length,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
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
        cardCount: data['cardCount'] ?? 0,
        imageUrl: data['imageUrl'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<Flashcard>> generateFlashCards(
    String topic,
    int count,
    bool useImages,
  ) async {
    try {
      // Use Firebase AI for text generation
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.array(
            items: Schema.object(
              properties: {'front': Schema.string(), 'back': Schema.string()},
            ),
          ),
        ),
      );

      final promptText =
          '''
      You are a strict teacher. 
      Generate exactly $count flashcards about "$topic".
      Return a JSON array where each object has "front" and "back" keys.
      ''';

      final content = [Content.text(promptText)];
      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) throw Exception("AI returned empty response");

      List<dynamic> jsonList = [];
      try {
        jsonList = jsonDecode(responseText);
      } catch (e) {
        // Fallback robust parsing
        int startIndex = responseText.indexOf('[');
        int endIndex = responseText.lastIndexOf(']');
        if (startIndex != -1 && endIndex != -1) {
          final jsonStr = responseText.substring(startIndex, endIndex + 1);
          jsonList = jsonDecode(jsonStr);
        }
      }

      final cards = <Flashcard>[];

      for (var item in jsonList) {
        cards.add(
          Flashcard.newCard(
            id: '',
            deckId: '',
            front: item['front'] ?? 'Error',
            back: item['back'] ?? 'Error',
            // imageUrl remains null as requested
          ),
        );
      }

      return cards;
    } catch (e) {
      debugPrint("AI Generation Error: $e");
      return [];
    }
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
}
