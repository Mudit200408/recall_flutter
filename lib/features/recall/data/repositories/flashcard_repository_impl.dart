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

import 'package:supabase_flutter/supabase_flutter.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FirebaseFirestore firestore;
  final SupabaseClient supabase;
  final String userId;
  final http.Client httpClient;
  final String modelId;
  final ImageGenerationService imageService;

  FlashcardRepositoryImpl({
    required this.firestore,
    required this.supabase,
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
    bool useImages = false,
    String topic = '',
    int scheduledDays = 0,
    int dailyCardCount = 0,
    int easyCount = 0,
    int hardCount = 0,
    int failCount = 0,
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
      'cardCount': cards.length,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'topic': topic,
      'scheduledDays': scheduledDays,
      'daysGenerated': 1,
      'lastGeneratedDate': FieldValue.serverTimestamp(),
      'dailyCardCount': dailyCardCount,
      'useImages': useImages,
      'easyCount': easyCount,
      'hardCount': hardCount,
      'failCount': failCount,
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
        topic: data['topic'] ?? '',
        scheduledDays: data['scheduledDays'] ?? 0,
        daysGenerated: data['daysGenerated'] ?? 0,
        lastGeneratedDate: (data['lastGeneratedDate'] as Timestamp?)?.toDate(),
        dailyCardCount: data['dailyCardCount'] ?? 0,
        useImages: data['useImages'] ?? false,
        easyCount: data['easyCount'] ?? 0,
        hardCount: data['hardCount'] ?? 0,
        failCount: data['failCount'] ?? 0,
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

    // Helper function to extract path from Supabase URL
    String? getPathFromUrl(String url) {
      try {
        final uri = Uri.parse(url);
        // Supabase public URL format: .../storage/v1/object/public/bucket/path/to/file
        final segments = uri.pathSegments;
        final publicIndex = segments.indexOf('public');
        if (publicIndex != -1 &&
            publicIndex + 2 < segments.length &&
            segments[publicIndex + 1] == 'deck_images') {
          return segments.sublist(publicIndex + 2).join('/');
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    // 1. Get Deck Data to find image URL
    final deckSnapshot = await deckRef.get();
    final deckData = deckSnapshot.data();
    if (deckData != null && deckData['imageUrl'] != null) {
      final imageUrl = deckData['imageUrl'] as String;
      final path = getPathFromUrl(imageUrl);
      if (path != null) {
        try {
          await supabase.storage.from('deck_images').remove([path]);
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
        final path = getPathFromUrl(cardImageUrl);
        if (path != null) {
          try {
            await supabase.storage.from('deck_images').remove([path]);
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
      final split = base64Image.split(',');
      final imageString = split.length == 2 ? split.last : base64Image;
      final data = base64Decode(imageString);

      // 2. Create Filename
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.png';
      final path = 'users/$userId/$filename';

      // 3. Upload to Supabase
      await supabase.storage
          .from('deck_images')
          .uploadBinary(
            path,
            data,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );

      // 4. Get Public URL
      return supabase.storage.from('deck_images').getPublicUrl(path);
    } catch (e) {
      debugPrint("Supabase Storage Upload Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> generateMoreCards(Deck deck) async {
    // Check if we reached the scheduled days
    if (deck.daysGenerated >= deck.scheduledDays) return;

    // Generate new cards
    final newCards = await generateFlashCards(
      deck.topic,
      deck.dailyCardCount,
      deck.useImages,
    );

    if (newCards.isEmpty) return;

    // Process images if needed (similar to saveDeck)
    for (final card in newCards) {
      if (deck.useImages && card.imageUrl == null) {
        // Generate image for the card if it wasn't generated by generateFlashCards (which mimics behaviour based on useImages param)
        // Wait, generateFlashCards (my implementation) doesn't generate images for cards yet!
        // The implementation calls ImageGenerationService inside it? No, checking generateFlashCards...
        // It returns cards with imageUrl = null.
        // We need to generate images here if useImages is true.
        // Wait, checking saveDeck... it does this:
        /*
         if (cardImageUrl != null && cardImageUrl.startsWith('data:image')) {
            // upload
         }
        */
        // But `generateFlashCards` implementation (lines 174-238) sets imageUrl to null!
        // So `saveDeck` loop for images only works if card.imageUrl is ALREADY set.
        // BUT, `saveDeck` implementation doesn't call image generation service for CARDS, only DECK.
        // I need to check if `generateFlashCards` should generate images.
        // It calls `imageService.generateDeckImage` for DECK in `saveDeck`.
        // It does NOT seem to generate images for CARDS in `saveDeck` unless they are already there.
        // And `generateFlashCards` definitely returns null imageUrl.
        // So effectively, card images are NOT generated currently in the codebase for AI cards?
        // Let's look at `FlashcardRepositoryImpl.generateFlashCards` again (lines 174-238).
        // It definitely sets imageUrl: null.
        // So unless I fix that, new cards won't have images either.
        // But the user prompt says "if user selects 3 days then the flashcards will automatically generate the questions...".
        // It implies existing functionality extension.
        // If current AI generation DOES NOT support card images, I shouldn't burden this task with adding it unless necessary.
        // However, `saveDeck` DOES check for card images.
        // Maybe the `Flashcard` entity passed to `saveDeck` comes from somewhere else?
        // Ah, `generateFlashCards` is used in `DeckBloc` _onCreateDeck.
        // There it calls `repository.generateFlashCards`.
        // Then it calls `repository.saveDeck`.
        // So currently, NO images are generated for cards.
        // Validated by reading `generateFlashCards`.
        // So I don't need to worry about card images for now.
        // Just deck image. But deck image is already set on the deck.
      }
    }

    // Determine batch
    final batch = firestore.batch();
    final deckRef = firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deck.id);

    // Add new cards
    for (final card in newCards) {
      final cardRef = deckRef.collection('cards').doc();
      final cardModel = FlashcardModel(
        id: cardRef.id,
        deckId: deck.id,
        front: card.front,
        back: card.back,
        interval: 0,
        repetitions: 0,
        easeFactor: 2.5,
        dueDate: DateTime.now(),
        imageUrl: null, // As discussed, no card images
      );
      batch.set(cardRef, cardModel.toJson());
    }

    // Update Deck stats
    batch.update(deckRef, {
      'cardCount': FieldValue.increment(newCards.length),
      'daysGenerated': FieldValue.increment(1),
      'lastGeneratedDate': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> updateDeckStats(
    String deckId, {
    int easyIncrement = 0,
    int hardIncrement = 0,
    int failIncrement = 0,
  }) async {
    final deckRef = firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId);

    await deckRef.update({
      'easyCount': FieldValue.increment(easyIncrement),
      'hardCount': FieldValue.increment(hardIncrement),
      'failCount': FieldValue.increment(failIncrement),
    });
  }
}
