import 'package:recall/features/recall/domain/entities/flashcard.dart';

class SpacedRepetitionService {
  Flashcard calculateNextReview(Flashcard card, int quality) {

    // Default Values
    int newRepetitions = card.repetitions;
    double newEaseFactor = card.easeFactor;
    int newInterval = card.interval;

    // STEP 1: Check if the user failed (Quality < 2)
    if(quality < 2) {
      newRepetitions = 0;
      newInterval = 1;
    } 
    
    // STEP 2: Check if the user passed (Quality >= 2)
    else {

      // Calculate new Ease Factor
      newEaseFactor = card.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      // Constraints: Ease Factor should not drop below 1.3
      if (newEaseFactor < 1.3) newEaseFactor = 1.3;

      // Increment Repetitions
      newRepetitions = card.repetitions + 1;

      // Calculate new Interval based on Repetitons
      if (newRepetitions == 1) {
        newInterval = 1;
      } else if (newRepetitions == 2) {
        newInterval = 6;
      } else {
        newInterval = (card.interval * newEaseFactor).ceil();
       }
    }

    // STEP 3: Create new Due Date
    final newDueDate = DateTime.now().add(Duration(days: newInterval));

    // STEP 4: Return new Flashcard
    return card.copyWith(
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      interval: newInterval,
      dueDate: newDueDate,
    );
    
  }
}