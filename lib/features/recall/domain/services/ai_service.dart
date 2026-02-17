abstract class AiService {
  Future<List<FlashcardContent>> generateFlashcards(
    String title,
    String difficultyLevel,
    int count,
  );
}

class FlashcardContent {
  final String front;
  final String back;

  FlashcardContent({required this.front, required this.back});
}
