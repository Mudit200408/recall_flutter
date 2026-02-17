import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:recall/features/recall/domain/services/ai_service.dart';

// ✅ Top-level function — does both jsonDecode + mapping in one isolate call
List<FlashcardContent> _parseGeminiFlashcardsJson(String jsonString) {
  final List<dynamic> jsonList = jsonDecode(jsonString);
  return jsonList
      .map(
        (item) => FlashcardContent(
          front: item['front'] ?? 'Error',
          back: item['back'] ?? 'Error',
        ),
      )
      .toList();
}

class GeminiAiService implements AiService {
  @override
  Future<List<FlashcardContent>> generateFlashcards(
    String title,
    String difficultyLevel,
    int count,
  ) async {
    try {
      // Use Firebase AI for text generation
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3-flash-preview',
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
      Generate exactly $count flashcards about "$title".
      Difficulty Level of questions should be $difficultyLevel.
      Return a JSON array where each object has "front" and "back" keys.
      ''';

      final content = [Content.text(promptText)];
      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) throw Exception("AI returned empty response");

      try {
        return await compute(_parseGeminiFlashcardsJson, responseText);
      } catch (e) {
        // Fallback robust parsing
        int startIndex = responseText.indexOf('[');
        int endIndex = responseText.lastIndexOf(']');
        if (startIndex != -1 && endIndex != -1) {
          final jsonStr = responseText.substring(startIndex, endIndex + 1);
          return await compute(_parseGeminiFlashcardsJson, jsonStr);
        }
        rethrow;
      }
    } catch (e) {
      debugPrint("AI Generation Error: $e");
      rethrow; // Rethrow to let the Bloc handle the error (and prevent deck creation)
    }
  }
}
