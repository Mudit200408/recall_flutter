import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:openrouter_api/openrouter_api.dart';
import 'package:recall/features/recall/data/models/flashcard_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FirebaseFirestore firestore;
  final String openRouterApiKey;
  final String userId;
  final http.Client httpClient;
  final String modelId;

  FlashcardRepositoryImpl({
    required this.firestore,
    required this.openRouterApiKey,
    required this.userId,
    required this.httpClient,
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
    for (final card in cards) {
      // Create a reference inside a new deck
      final cardRef = deckRef.collection('cards').doc();

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
        imageUrl: card.imageUrl,
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
      final inference = OpenRouter.inference(key: openRouterApiKey);

      final prompt =
          '''
      You are a strict teacher. 
      Generate exactly $count flashcards about "$topic".
      
      Return ONLY valid JSON.
      Structure: [ { "front": "...", "back": "..." } ]
      ''';

      final response = await inference.getCompletion(
        modelId: modelId,
        messages: [LlmMessage.user(LlmMessageContent.text(prompt))],
      );

      final responseText = response.choices?.first.content;
      if (responseText == null) throw Exception("AI returned empty response");

      List<dynamic> jsonList = [];
      bool parsedSuccessfully = false;

      // Robust Parsing: Try to find valid JSON array in the text
      int currentIndex = 0;
      while (true) {
        // Find next '['
        int startIndex = responseText.indexOf('[', currentIndex);
        if (startIndex == -1) break;

        // Find last ']' (we assume the JSON array ends at a closing bracket)
        // We search from the end of the string backwards, but it must be after startIndex
        int endIndex = responseText.lastIndexOf(']');
        if (endIndex <= startIndex) {
          currentIndex = startIndex + 1;
          continue;
        }

        try {
          final potentialJson = responseText.substring(
            startIndex,
            endIndex + 1,
          );
          jsonList = jsonDecode(potentialJson);
          parsedSuccessfully = true;
          break; // Success!
        } catch (e) {
          // If this chunk failed, maybe there is another '[' later?
          // e.g. "Here is an example [ ... ] and here is the real data [ ... ]"
          // We advance currentIndex to look for the next '['
          currentIndex = startIndex + 1;
        }
      }

      if (!parsedSuccessfully) {
        throw Exception(
          "Failed to extract valid JSON from response: $responseText",
        );
      }

      // Convert to Entities
      List<Flashcard> cards = jsonList.map((item) {
        return Flashcard.newCard(
          id: '',
          deckId: '',
          front: item['front'] ?? 'Error',
          back: item['back'] ?? 'Error',
        );
      }).toList();

      // Image Generation
      if (useImages) {
        for (var i = 0; i < cards.length; i++) {
          try {
            // Generate simplified prompt for image
            final imagePrompt =
                "Data visualization or icon representing: ${cards[i].back}";
            final imageUrl = await generateImageForCard(imagePrompt);
            cards[i] = cards[i].copyWith(imageUrl: imageUrl);
          } catch (e) {
            debugPrint("Skipping image for card $i: $e");
          }
        }
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

    // 1. Get all the cards in the deck
    final cardSnapshot = await deckRef.collection('cards').get();

    // 2. Delete all the cards
    for (var doc in cardSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(deckRef);
    await batch.commit();
  }

  @override
  Future<String> generateImageForCard(String prompt) async {
    try {
      // Use Pollinations.ai for free image generation (URL based)
      // Format: https://image.pollinations.ai/prompt/{prompt}
      // Encode the prompt
      final encodedPrompt = Uri.encodeComponent(prompt);
      final url = "https://image.pollinations.ai/prompt/$encodedPrompt";

      // We can just return the URL directly.
      // Ideally we might want to check if it's reachable, but for now just return it.
      return url;
    } catch (e) {
      debugPrint("Image Gen Error: $e");
      return "https://via.placeholder.com/300?text=Image+Error";
    }
  }
}
