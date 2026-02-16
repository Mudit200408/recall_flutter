import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:recall/features/recall/domain/services/ai_service.dart';

class GeminiAiService implements AiService {
  @override
  Future<List<FlashcardContent>> generateFlashcards(
    String title,
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

      final results = <FlashcardContent>[];

      for (var item in jsonList) {
        results.add(
          FlashcardContent(
            front: item['front'] ?? 'Error',
            back: item['back'] ?? 'Error',
          ),
        );
      }

      return results;
    } catch (e) {
      debugPrint("AI Generation Error: $e");
      rethrow; // Rethrow to let the Bloc handle the error (and prevent deck creation)
    }
  }
}
