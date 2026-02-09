import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class ImageGenerationService {
  late final GenerativeModel _model;

  ImageGenerationService() {
    // Initialize the model using the firebase_ai package
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-image', // User requested model
    );
  }

  Future<String?> generateDeckImage(String deckName) async {
    const promptTemplate =
        'Gamified vibe illustration of %s, video game concept art, high resolution, 4k, no text, minimal, vibrant colors, fantasy or sci-fi aesthetic';
    final prompt = promptTemplate.replaceAll('%s', deckName);
    return _generateImage(prompt);
  }


  Future<String?> _generateImage(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      // Check if the response contains inline data (image bytes)
      // Gemini 2.5 Flash Image returns the image as InlineDataPart
      if (response.candidates.isNotEmpty) {
        final parts = response.candidates.first.content.parts;
        for (var part in parts) {
          if (part is InlineDataPart) {
            // If we get raw bytes, convert to base64 for our app's existing logic
            return 'data:${part.mimeType};base64,${base64Encode(part.bytes)}';
          }
        }
      }

      // If we only get text, maybe it failed or model behavior isn't inline bytes.
      debugPrint("Vertex AI Response (Text): ${response.text}");
      return null;
    } catch (e) {
      debugPrint("Vertex AI Error: $e");
      return null;
    }
  }
}
