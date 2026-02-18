import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:recall/features/recall/data/service/model_management_service.dart';
import 'package:recall/features/recall/domain/services/ai_service.dart';

// ✅ Top-level function — required for compute() to work
// Instance methods can't be sent to another isolate because they capture `this`
List<FlashcardContent> _parseFlashcardsJson(String jsonString) {
  final List<dynamic> data = jsonDecode(jsonString);
  return data
      .map(
        (e) => FlashcardContent(
          front: e['front'].toString(),
          back: e['back'].toString(),
        ),
      )
      .toList();
}

class LocalAIService implements AiService {
  final ModelManagementService _modelManager = ModelManagementService();

  @override
  Future<List<FlashcardContent>> generateFlashcards(
    String topic,
    String difficultyLevel,
    int count,
  ) async {
    await _modelManager.ensureActiveModelLoaded();
    final model = await FlutterGemma.getActiveModel(maxTokens: 1024);
    final chat = await model.createChat();

    // STRICT PROMPT for smaller models (2b/7b)
    final prompt =
        '''
Generate $count flashcards about "$topic".
Return ONLY a valid JSON array of objects.
Difficulty Level of questions should be $difficultyLevel.
Each object must have "front" and "back" keys.
Do not include any other text, explanations, or markdown formatting.

Example:
[{"front": "Question 1", "back": "Answer 1"}, {"front": "Question 2", "back": "Answer 2"}]
''';

    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

    final responseText = await model.session!.getResponse();

    if (responseText.isEmpty) {
      throw Exception("Model returned Empty text");
    }

    // 1. Strip Markdown code blocks if present
    String cleanResponse = responseText;
    if (cleanResponse.contains('```json')) {
      cleanResponse = cleanResponse
          .replaceAll('```json', '')
          .replaceAll('```', '');
    } else if (cleanResponse.contains('```')) {
      cleanResponse = cleanResponse.replaceAll('```', '');
    }

    // 2. Find the JSON array (first [ and last ])
    final int startIndex = cleanResponse.indexOf('[');
    final int endIndex = cleanResponse.lastIndexOf(']');

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);

      // Fix: Ensure commas between objects (common model error)
      cleanResponse = cleanResponse.replaceAll(RegExp(r'\}\s*\{'), '}, {');
    } else {
      debugPrint("Gemma Raw Response (No JSON found): $responseText");
      throw const FormatException("Could not find JSON array in response");
    }

    try {
      final result = await compute(_parseFlashcardsJson, cleanResponse);
      return result;
    } catch (e) {
      debugPrint("Gemma JSON Parse Error: $e");
      debugPrint("Attempted to parse: $cleanResponse");
      rethrow;
    }
  }
}
