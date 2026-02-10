import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:recall/core/network/connectivity_cubit.dart';
import 'package:recall/core/widgets/loader.dart';
import 'package:recall/features/recall/presentation/bloc/quiz/quiz_bloc.dart';
import 'package:recall/features/recall/presentation/pages/offline_view.dart';
import 'package:recall/features/recall/presentation/pages/quiz_completed_page.dart';
import 'package:recall/features/recall/presentation/pages/quiz_empty_page.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';
import 'package:recall/features/recall/presentation/widgets/flashcard_face.dart';
import 'package:recall/features/recall/presentation/widgets/flip_card_widget.dart';
import 'package:recall/features/recall/domain/entities/flashcard.dart';
import 'package:recall/features/recall/domain/entities/deck.dart';
import 'package:recall/features/recall/presentation/widgets/square_button.dart';
import 'package:recall/injection_container.dart' as di;
import 'package:responsive_framework/responsive_framework.dart';
import 'package:responsive_scaler/responsive_scaler.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

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

class _QuizContentState extends State<QuizContent> {
  final CardSwiperController _swiperController = CardSwiperController();
  bool _isSwiping = false;

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  bool _handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    print(
      'DEBUG: [QuizPage] _handleSwipe called. isFlipped: ${widget.state.isFlipped}, Direction: $direction',
    );
    if (!widget.state.isFlipped) {
      print("DEBUG: [QuizPage] Cannot swipe - not flipped");
      return false;
    }

    // Immediately mark swiping to prevent background card from getting isFlipped
    setState(() {
      _isSwiping = true;
    });

    if (direction == CardSwiperDirection.right) {
      final isLastCard = widget.state.remainingCards.length == 1;
      Future.delayed(Duration(milliseconds: isLastCard ? 15 : 300), () {
        if (mounted) {
          _isSwiping = false;
          HapticFeedback.lightImpact();
          context.read<QuizBloc>().add(RateCard(rating: 5)); // Know it
        }
      });
    } else if (direction == CardSwiperDirection.left) {
      final isLastCard = widget.state.remainingCards.length == 1;
      Future.delayed(Duration(milliseconds: isLastCard ? 15 : 300), () {
        if (mounted) {
          _isSwiping = false;
          HapticFeedback.lightImpact();
          context.read<QuizBloc>().add(RateCard(rating: 3)); // Review
        }
      });
    }
    return true;
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

  Widget _buildMobileView(
    BuildContext context,
    List<Flashcard> remainingCards,
    Flashcard topCard,
    bool isMobile,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(context),
            SizedBox(height: 16.scale()),

            _buildProgressBar(),
            SizedBox(height: 16.scale()),

            _buildCard(remainingCards, isMobile),

            // Swipe hints
            if (widget.state.isFlipped)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.scale(),
                  vertical: 12.scale(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color: Colors.orange,
                          size: 20.scale(),
                        ),
                        SizedBox(width: 4.scale()),
                        Text(
                          "REVIEW",
                          style: TextStyle(
                            fontSize: 12.scale(),
                            fontVariations: [FontVariation.weight(700)],
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "KNOW IT",
                          style: TextStyle(
                            fontSize: 12.scale(),
                            fontVariations: [FontVariation.weight(700)],
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(width: 4.scale()),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.green,
                          size: 20.scale(),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.scale()),
                child: Text(
                  "TAP TO REVEAL",
                  style: TextStyle(
                    fontSize: 12.scale(),
                    fontVariations: [FontVariation.weight(700)],
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Flashcard> remainingCards, bool isMobile) {
    return Expanded(
      child: Stack(
        children: [
          Center(
            child: CardSwiper(
              key: ValueKey(
                "${remainingCards.length}_${widget.state.isFlipped}",
              ), // Rebuild on flip to update disabled swipe state
              controller: _swiperController,
              cardsCount: remainingCards.length,
              numberOfCardsDisplayed: remainingCards.length.clamp(1, 3),
              backCardOffset: isMobile ? Offset(0, 45) : Offset(30, 38),
              scale: 0.9,
              padding: EdgeInsets.all(24.scale()),
              allowedSwipeDirection: widget.state.isFlipped
                  ? const AllowedSwipeDirection.only(left: true, right: true)
                  : const AllowedSwipeDirection.none(),
              onSwipe: widget.state.isFlipped ? _handleSwipe : null,
              cardBuilder:
                  (
                    context,
                    index,
                    horizontalThresholdPercentage,
                    verticalThresholdPercentage,
                  ) {
                    final card = remainingCards[index];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (!widget.state.isFlipped) {
                                  HapticFeedback.lightImpact();
                                  context.read<QuizBloc>().add(FlipCard());
                                }
                              },
                              // PATCH: Explicitly consume drag gestures when not flipped
                              // to prevent CardSwiper from receiving them.
                              onHorizontalDragUpdate: !widget.state.isFlipped
                                  ? (_) {}
                                  : null,
                              onVerticalDragUpdate: !widget.state.isFlipped
                                  ? (_) {}
                                  : null,
                              onHorizontalDragStart: !widget.state.isFlipped
                                  ? (_) {}
                                  : null,
                              onVerticalDragStart: !widget.state.isFlipped
                                  ? (_) {}
                                  : null,
                              child: FlipCardWidget(
                                key: ValueKey(card.id),
                                isFlipped:
                                    widget.state.isFlipped &&
                                    index == 0 &&
                                    !_isSwiping,
                                front: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 4.0,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: ClipRRect(
                                    child: FlashcardFace(
                                      text: card.front,
                                      color: Colors.deepPurple,
                                      label: "QUESTION",
                                    ),
                                  ),
                                ),
                                back: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 4.0,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: ClipRRect(
                                    child: FlashcardFace(
                                      text: card.back,
                                      color: Colors.indigo,
                                      label: "ANSWER",
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Right swipe overlay (Know it - Green)
                            if (widget.state.isFlipped &&
                                horizontalThresholdPercentage > 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha:
                                            (horizontalThresholdPercentage /
                                                    100)
                                                .abs()
                                                .clamp(0.0, 0.7),
                                      ),
                                      border: Border.all(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                    child: Center(
                                      child: Opacity(
                                        opacity:
                                            (horizontalThresholdPercentage /
                                                    100)
                                                .abs()
                                                .clamp(0.0, 1.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/svg/easy.svg',
                                              height: 64.scale(),
                                              width: 64.scale(),
                                              colorFilter: ColorFilter.mode(
                                                Colors.white,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            SizedBox(height: 8.scale()),
                                            Text(
                                              "NAILED IT",
                                              style: TextStyle(
                                                fontSize: 24.scale(),
                                                fontVariations: [
                                                  FontVariation.weight(900),
                                                ],
                                                color: Colors.white,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Left swipe overlay (Review - Orange)
                            if (widget.state.isFlipped &&
                                horizontalThresholdPercentage < 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha:
                                            (horizontalThresholdPercentage /
                                                    100)
                                                .abs()
                                                .clamp(0.0, 0.7),
                                      ),
                                      border: Border.all(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                    child: Center(
                                      child: Opacity(
                                        opacity:
                                            (horizontalThresholdPercentage /
                                                    100)
                                                .abs()
                                                .clamp(0.0, 1.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/svg/hard.svg',
                                              height: 64.scale(),
                                              width: 64.scale(),
                                              colorFilter: ColorFilter.mode(
                                                Colors.white,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            SizedBox(height: 8.scale()),
                                            Text(
                                              "REVIEW",
                                              style: TextStyle(
                                                fontSize: 24.scale(),
                                                fontVariations: [
                                                  FontVariation.weight(900),
                                                ],
                                                color: Colors.white,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    if (widget.state.remainingCards.isEmpty && widget.state.totalCards > 0) {
      // Quiz completed logic handled by parent or different state
      return const SizedBox.shrink();
    }

    // Safety check for empty cards
    if (widget.state.remainingCards.isEmpty) return const SizedBox.shrink();

    final remainingCards = widget.state.remainingCards;
    // topCard is remainingCards[0]

    return _buildMobileView(
      context,
      remainingCards,
      remainingCards.first,
      isMobile,
    );
  }
}
