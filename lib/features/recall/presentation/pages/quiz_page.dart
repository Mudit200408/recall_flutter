import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/features/recall/presentation/bloc/quiz/quiz_bloc.dart';
import 'package:recall/features/recall/presentation/pages/quiz_completed_page.dart';
import 'package:recall/features/recall/presentation/widgets/flashcard_face.dart';
import 'package:recall/features/recall/presentation/widgets/flip_card_widget.dart';
import 'package:recall/features/recall/presentation/widgets/rating_button.dart';
import 'package:recall/injection_container.dart' as di;

class QuizPage extends StatelessWidget {
  final String deckId;
  final String deckTitle;
  const QuizPage({super.key, required this.deckId, required this.deckTitle});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          QuizBloc(repository: context.read(), notificationService: di.sl())
            ..add(StartQuiz(deckId: deckId)),
      child: Scaffold(
        appBar: AppBar(
          title: Hero(
            tag: 'deck-title-$deckId', // Must match the tag from the list!
            child: Material(
              color: Colors.transparent,
              child: Text(
                deckTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        body: BlocBuilder<QuizBloc, QuizState>(
          builder: (context, state) {
            switch (state) {
              case QuizLoading _:
                return const Center(child: CircularProgressIndicator());

              case QuizEmpty _:
                return const Center(child: Text("No cards available"));

              case QuizFinished _:
                return QuizCompletedPage();
              case QuizActive state:
                return _buildQuizContent(context, state);
              case _:
                return SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuizContent(BuildContext context, QuizActive state) {
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .stretch,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.read<QuizBloc>().add(FlipCard()),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: FlipCardWidget(
                isFlipped: state.isFlipped,
                front: FlashcardFace(
                  text: state.currentCard.front,
                  color: Colors.deepPurple,
                  label: "QUESTION",
                ),
                back: FlashcardFace(
                  text: state.currentCard.back,
                  color: Colors.indigo, // Slightly different color for back
                  label: "ANSWER",
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 24),

        if (!state.isFlipped)
          ElevatedButton(
            onPressed: () => context.read<QuizBloc>().add(FlipCard()),
            child: Text("Show Answer"),
          )
        else
          Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              RatingButton(label: "Again", color: Colors.red, rating: 1),
              RatingButton(label: "Hard", color: Colors.orange, rating: 3),
              RatingButton(label: "Good", color: Colors.blue, rating: 4),
              RatingButton(label: "Easy", color: Colors.green, rating: 5),
            ],
          ),
      ],
    );
  }
}
