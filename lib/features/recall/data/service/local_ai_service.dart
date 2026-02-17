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

    // Attempt to extract JSON array using regex if the response is cluttered
    String contentToParse = responseText;
    final jsonArrayRegex = RegExp(r'\[.*\]', dotAll: true);
    final match = jsonArrayRegex.firstMatch(responseText);
    if (match != null) {
      contentToParse = match.group(0)!;
    }

    try {
      final result = await compute(_parseFlashcardsJson, contentToParse);
      return result;
    } catch (e) {
      debugPrint("Gemma JSON Parse Error: $responseText");

      // Fallback: Try to repair the JSON or parse loosely if it's really broken
      // This is a simple fallback for common small-model errors like missing closing brackets
      try {
        contentToParse = contentToParse.trim();
        if (!contentToParse.endsWith(']')) {
          // Try appending closing bracket
          final int lastBrace = contentToParse.lastIndexOf('}');
          if (lastBrace != -1) {
            contentToParse = '${contentToParse.substring(0, lastBrace + 1)}]';
            final result = await compute(_parseFlashcardsJson, contentToParse);
            return result;
          }
        }
      } catch (_) {}

      rethrow;
    }
  }
}
