import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class QuizCompletedPage extends StatelessWidget {
  const QuizCompletedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Lottie.asset('assets/lottie/quiz_completed.json'),
            const SizedBox(height: 16),
            Text("Quiz Completed", style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Back to decks"),
            ),
          ],
        ),
      ),
    );
  }
}
