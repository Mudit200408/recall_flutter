import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/cupertino.dart';
import 'package:recall/features/recall/data/models/flashcard_model.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';
import 'package:recall/features/recall/domain/repositories/flashcard_repository.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FirebaseFirestore firestore;
  final GenerativeModel aiModel;
  final String userId;

  FlashcardRepositoryImpl({required this.firestore, required this.aiModel, required this.userId});


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
  Future<void> saveDeck(String deckTitle, List<Flashcard> cards) async {
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
      );
    }).toList();
  }

  @override
  Future<List<Flashcard>> generateFlashCards(String sourceText) async {
    try {
      // 1: Construct the prompt
      final prompt = Content.text('''
        You are a strict teacher. Analyze the following text and generate 5-10 flashcards.
        Return ONLY valid JSON. Do not add markdown formatting (no ```json tags).
        
        Structure:
        [
          { "front": "Question here", "back": "Answer here" }
        ]

        Text to analyze:
        $sourceText
      ''');

      // 2: Call Gemini
      final response = await aiModel.generateContent([prompt]);

      // 3: Parse Response
      final responseText = response.text;
      if (responseText == null) throw Exception("AI returned empty response");

      // Sanitize: Remove markdown if the AI adds it despite instructions
      final cleanJson = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final List<dynamic> jsonList = jsonDecode(cleanJson);

      // 4: Convert to Entites
      return jsonList.map((item) {
        return Flashcard.newCard(
          id: '',
          deckId: '',
          front: item['front'] ?? 'Error',
          back: item['back'] ?? 'Error',
        );
      }).toList();
    } catch (e) {
      debugPrint("AI Generation Error: $e");
      return [];
    }
  }
}
