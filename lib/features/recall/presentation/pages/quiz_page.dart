import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/features/recall/presentation/bloc/quiz/quiz_bloc.dart';
import 'package:recall/features/recall/presentation/pages/quiz_completed_page.dart';
import 'package:recall/features/recall/presentation/pages/quiz_empty_page.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';
import 'package:recall/features/recall/presentation/widgets/flashcard_face.dart';
import 'package:recall/features/recall/presentation/widgets/flip_card_widget.dart';
import 'package:recall/features/recall/presentation/widgets/rating_button.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/presentation/widgets/square_button.dart';
import 'package:recall/injection_container.dart' as di;

class QuizPage extends StatelessWidget {
  final Deck deck;
  const QuizPage({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          QuizBloc(repository: context.read(), notificationService: di.sl())
            ..add(StartQuiz(deck: deck)),
      child: Scaffold(
        // appBar: AppBar(
        //   automaticallyImplyLeading: false,
        // leading: Container(
        //   margin: EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     border: Border.all(color: Colors.black, width: 3),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black,
        //         offset: const Offset(2, 2),
        //         blurRadius: 0,
        //       ),
        //     ],
        //   ),

        //   child: IconButton(
        //     icon: const Icon(Icons.arrow_back),
        //     onPressed: () => Navigator.pop(context),
        //     padding: EdgeInsets.zero,
        //     splashColor: Colors.transparent,
        //   ),
        // ),
        //   title: Hero(
        //     tag: 'deck-title-${deck.id}', // Must match the tag from the list!
        //     child: Material(
        //       color: Colors.transparent,
        //       child: Text(
        //         deck.title.toUpperCase(),
        //         style: const TextStyle(
        //           fontSize: 20,
        //           fontVariations: [FontVariation.weight(900)],
        //           letterSpacing: 1.3,
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
        body: SafeArea(
          child: BlocBuilder<QuizBloc, QuizState>(
            builder: (context, state) {
              switch (state) {
                case QuizLoading _:
                  return const Center(child: CircularProgressIndicator());

                case QuizEmpty state:
                  return QuizEmptyPage(deck: state.deck);

                case QuizFinished state:
                  return QuizCompletedPage(
                    deck: state.deck,
                    easyCount: state.easyCount,
                    hardCount: state.hardCount,
                    failCount: state.failCount,
                    isDeckDeleted: state.isDeckDeleted,
                  );
                case QuizActive state:
                  return QuizContent(state: state);
                case _:
                  return SizedBox.shrink();
              }
            },
          ),
        ),
      ),
    );
  }
}

class QuizContent extends StatefulWidget {
  final QuizActive state;
  const QuizContent({super.key, required this.state});

  @override
  State<QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends State<QuizContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  Flashcard? _animatingCard;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant QuizContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentCard != widget.state.currentCard) {
      // New card arrived, reset animation instantly
      _controller.value = 0;
      _animatingCard = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRating(int rating, Offset direction) {
    if (_controller.isAnimating) return;

    setState(() {
      _animatingCard = widget.state.currentCard;
      _animation = Tween<Offset>(
        begin: Offset.zero,
        end: direction,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    });

    _controller.forward().then((_) {
      context.read<QuizBloc>().add(RateCard(rating: rating));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Current card is either the one in state, or if we are animating, the one we captured.
    final topCard = _animatingCard ?? widget.state.currentCard;

    // Bottom card (Next) is the one in state IF we are currently animating the old one away.
    // Or if we are just viewing, the bottom card is the next one in the list.
    // Wait, if we are animating 'currentCard' away, the 'state.currentCard' is still the same until Bloc updates.
    // So 'topCard' is visually the one flying away.
    // We need to show what's underneath.
    // Underneath is the NEXT card in the list (remainingCards[1]).

    Flashcard? bottomCard;
    if (widget.state.remainingCards.length > 1) {
      bottomCard = widget.state.remainingCards[1];
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: .stretch,
      spacing: 20,
      children: [
        Row(
          children: [
            const SizedBox(width: 16),
            SquareButton(
              icon: Icons.close,
              color: Colors.red,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
            Text(
              widget.state.deck.title,
              style: const TextStyle(
                fontSize: 32,
                fontVariations: [FontVariation.weight(900)],
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Stack(
                  alignment: AlignmentGeometry.center,
                  children: [
                    LinearProgressIndicator(
                      value:
                          (widget.state.totalCards -
                              widget.state.remainingCards.length +
                              1) /
                          widget.state.totalCards,
                      minHeight: 28,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFCCFF00),
                      ),
                    ),
                    Text(
                      "${widget.state.totalCards - widget.state.remainingCards.length + 1} / ${widget.state.totalCards}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontVariations: [FontVariation.weight(900)],
                        color: Colors.black,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bottom Card (The Next Card)
              if (bottomCard != null)
                Transform.scale(
                  scale: 0.95, // Slight scale effect for depth
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 24.0,
                    ),
                    child: FlashcardFace(
                      text: bottomCard.front,
                      color: Colors.deepPurple,
                      label: "QUESTION",
                    ),
                  ),
                ),

              // Top Card (The Active Card)
              SlideTransition(
                position: _animation,
                child: GestureDetector(
                  onTap: () => context.read<QuizBloc>().add(FlipCard()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 24.0,
                    ),
                    child: FlipCardWidget(
                      key: ValueKey(topCard.id),
                      isFlipped: widget.state.isFlipped,
                      front: FlashcardFace(
                        text: topCard.front,
                        color: Colors.deepPurple,
                        label: "QUESTION",
                      ),
                      back: FlashcardFace(
                        text: topCard.back,
                        color: Colors.indigo,
                        label: "ANSWER",
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (!widget.state.isFlipped)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10),
            child: AnimatedButton(
              text: "DECRYPT",
              icon: Icons.lock_open,
              onTap: () {
                context.read<QuizBloc>().add(FlipCard());
              },
              iconSide: 'left',
            ),
          )
        else
          Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              RatingButton(
                label: "FAIL",
                color: Colors.red,
                rating: 1,
                assetName: 'assets/svg/fail.svg',
                onPressed: () =>
                    _handleRating(1, const Offset(-1.5, 0)), // Right
              ),
              RatingButton(
                label: "HARD",
                color: Colors.yellow,
                rating: 3,
                assetName: 'assets/svg/hard.svg',
                onPressed: () => _handleRating(3, const Offset(0, -1.5)), // Top
              ),
              RatingButton(
                label: "EASY",
                color: const Color.fromARGB(255, 90, 223, 97),
                rating: 5,
                assetName: 'assets/svg/easy.svg',
                onPressed: () => _handleRating(5, const Offset(1.5, 0)), // Left
              ),
            ],
          ),
      ],
    );
  }
}
