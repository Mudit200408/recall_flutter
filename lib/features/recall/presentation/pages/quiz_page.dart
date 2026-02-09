import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/network/connectivity_cubit.dart';
import 'package:recall/core/widgets/loader.dart';
import 'package:recall/features/recall/presentation/bloc/quiz/quiz_bloc.dart';
import 'package:recall/features/recall/presentation/pages/offline_view.dart';
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
import 'package:responsive_framework/responsive_framework.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

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
        body: SafeArea(
          child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectivityState) {
              final isOffline = connectivityState is ConnectivityOffline;

              return BlocBuilder<QuizBloc, QuizState>(
                builder: (context, state) {
                  switch (state) {
                    case QuizLoading _:
                      return const Center(child: Loader());

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

                    case QuizError state:
                      final message = state.message.toLowerCase();
                      if (message.contains('connection') ||
                          message.contains('network') ||
                          message.contains('socket') ||
                          message.contains('offline') ||
                          message.contains('clientexception') ||
                          isOffline == true) {
                        return OfflineView(
                          onRetry: () {
                            context.read<QuizBloc>().add(StartQuiz(deck: deck));
                          },
                        );
                      }

                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.scale()),
                          child: Container(
                            constraints: BoxConstraints(maxWidth: 400.scale()),
                            padding: EdgeInsets.all(24.scale()),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black,
                                width: 4.scale(),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(8, 8),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64.scale(),
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16.scale()),
                                Text(
                                  "OOPS!",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 12.scale()),
                                Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.scale(),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 24.scale()),
                                AnimatedButton(
                                  text: "GO BACK",
                                  icon: Icons.arrow_back,
                                  onTap: () => Navigator.pop(context),
                                  iconSide: 'left',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                    case QuizActive state:
                      return isOffline
                          ? OfflineView(
                              onRetry: () {
                                context.read<QuizBloc>().add(
                                  StartQuiz(deck: deck),
                                );
                              },
                            )
                          : QuizContent(state: state);
                    case _:
                      return SizedBox.shrink();
                  }
                },
              );
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
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

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

    return isMobile
        ? _buildMobileView(context, bottomCard, topCard)
        : _buildTabletView(context, bottomCard, topCard);
  }

  Widget _buildTabletView(
    BuildContext context,
    Flashcard? bottomCard,
    Flashcard topCard,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Header Row with close button and title
        _buildHeader(context),
        SizedBox(height: 16.scale()),

        // Progress Bar
        _buildProgressBar(),
        SizedBox(height: 24.scale()),

        // Main Content: Card on left, Actions on right
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Flashcard Stack
              Flexible(
                flex: 2,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Bottom Card (The Next Card)
                    if (bottomCard != null) _buildFlashcardFace(bottomCard),

                    // Top Card (The Active Card)
                    _buildFlipCard(context, topCard),
                  ],
                ),
              ),

              SizedBox(width: 28.scale()),

              // Action Buttons (on the right side)
              Flexible(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!widget.state.isFlipped)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 250),
                        child: _buildDecryptButton(context),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RatingButton(
                            label: "EASY",
                            color: const Color.fromARGB(255, 90, 223, 97),
                            rating: 5,
                            assetName: 'assets/svg/easy.svg',
                            onPressed: () =>
                                _handleRating(5, const Offset(1.5, 0)),
                          ),
                          SizedBox(height: 16.scale()),
                          RatingButton(
                            label: "HARD",
                            color: Colors.yellow,
                            rating: 3,
                            assetName: 'assets/svg/hard.svg',
                            onPressed: () =>
                                _handleRating(3, const Offset(0, -1.5)),
                          ),
                          SizedBox(height: 16.scale()),
                          RatingButton(
                            label: "FAIL",
                            color: Colors.red,
                            rating: 1,
                            assetName: 'assets/svg/fail.svg',
                            onPressed: () =>
                                _handleRating(1, const Offset(-1.5, 0)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.scale()),
      ],
    );
  }

  Transform _buildFlashcardFace(Flashcard bottomCard) {
    return Transform.scale(
      scale: 0.95,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400),
        child: FlashcardFace(
          text: bottomCard.front,
          color: Colors.deepPurple,
          label: "QUESTION",
        ),
      ),
    );
  }

  Padding _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.scale()),
      child: Row(
        children: [
          SquareButton(
            icon: Icons.close,
            color: Colors.red,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: 16.scale()),
          Expanded(
            child: Text(
              widget.state.deck.title,
              style: TextStyle(
                fontSize: 28.scale(),
                fontVariations: [FontVariation.weight(900)],
                letterSpacing: 1.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Padding _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.scale()),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 700),
        child: Container(
          height: 40.scale(),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 3),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              LinearProgressIndicator(
                value:
                    (widget.state.totalCards -
                        widget.state.remainingCards.length +
                        1) /
                    widget.state.totalCards,
                minHeight: 35.scale(),
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFCCFF00),
                ),
              ),
              Text(
                "${widget.state.totalCards - widget.state.remainingCards.length + 1} / ${widget.state.totalCards}",
                style: TextStyle(
                  fontSize: 18.scale(),
                  fontVariations: [FontVariation.weight(900)],
                  color: Colors.black,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildMobileView(
    BuildContext context,
    Flashcard? bottomCard,
    Flashcard topCard,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        _buildHeader(context),

        _buildProgressBar(),

        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bottom Card (The Next Card)
              if (bottomCard != null) _buildFlashcardFace(bottomCard),

              // Top Card (The Active Card)
              _buildFlipCard(context, topCard),
            ],
          ),
        ),

        if (!widget.state.isFlipped)
          Padding(
            padding: EdgeInsets.only(
              left: 16.scale(),
              right: 16.scale(),
              bottom: 10.scale(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: _buildDecryptButton(context),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

  AnimatedButton _buildDecryptButton(BuildContext context) {
    return AnimatedButton(
      text: "DECRYPT",
      icon: Icons.lock_open,
      onTap: () {
        context.read<QuizBloc>().add(FlipCard());
      },
      iconSide: 'left',
    );
  }

  SlideTransition _buildFlipCard(BuildContext context, Flashcard topCard) {
    return SlideTransition(
      position: _animation,
      child: GestureDetector(
        onTap: () => context.read<QuizBloc>().add(FlipCard()),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
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
    );
  }
}
