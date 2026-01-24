import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/features/recall/presentation/bloc/quiz/quiz_bloc.dart';
import 'package:recall/features/recall/presentation/widgets/rating_button.dart';

class QuizPage extends StatelessWidget {
  final String deckId;
  final String deckTitle;
  const QuizPage({super.key, required this.deckId, required this.deckTitle});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          QuizBloc(repository: context.read())..add(StartQuiz(deckId: deckId)),
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
                return Scaffold(
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 100),
                      const SizedBox(height: 16),
                      Text("Quiz Completed"),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Back to decks"),
                      ),
                    ],
                  ),
                );
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
            child: Card(
              elevation: 4,
              child: Center(
                child: Text(
                  state.isFlipped
                      ? state.currentCard.back
                      : state.currentCard.front,
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
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
