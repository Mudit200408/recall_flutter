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
import 'package:recall/features/recall/presentation/widgets/progress_bar.dart';
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
    if (!widget.state.isFlipped) {
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

  Widget _buildProgressBar() {
    final int current =
        widget.state.totalCards - widget.state.remainingCards.length + 1;
    final int total = widget.state.totalCards;
    final double progress = current / total;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.scale()),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row: "PROGRESS" label + fraction counter
            Padding(
              padding: EdgeInsets.only(bottom: 6.scale()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PROGRESS",
                    style: TextStyle(
                      fontSize: 14.scale(),
                      fontVariations: const [FontVariation.weight(900)],
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "$current/$total",
                    style: TextStyle(
                      fontSize: 14.scale(),
                      fontVariations: const [FontVariation.weight(900)],
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            // The progress bar itself
            ProgressBar(progress: progress),
          ],
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
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

              _buildCard(remainingCards, isMobile, maxCardWidth: 400),

              // Swipe hints
              _buildSwipeHints(),
              SizedBox(height: 32.scale()), // Bottom padding for scroll
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeHints() {
    if (widget.state.isFlipped) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 26.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.orange, size: 20.r),
                SizedBox(width: 4.w),
                Text(
                  "REVIEW",
                  style: TextStyle(
                    fontSize: 12,
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
                    fontSize: 12,
                    fontVariations: [FontVariation.weight(700)],
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(Icons.arrow_forward, color: Colors.green, size: 20.r),
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 26.r),
        child: Text(
          "TAP TO DECRYPT",
          style: TextStyle(
            fontSize: 12,
            fontVariations: [FontVariation.weight(700)],
            color: Colors.grey,
          ),
        ),
      );
    }
  }

  Widget _buildTabletView(
    BuildContext context,
    List<Flashcard> remainingCards,
    Flashcard topCard,
    bool isMobile,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 8.scale()),
              _buildHeader(context),
              SizedBox(height: 16.scale()),

              _buildProgressBar(),
              SizedBox(height: 16.scale()),

              // Card takes all remaining vertical space
              _buildCard(remainingCards, isMobile, maxCardWidth: 700),

              // Swipe hints
              _buildSwipeHints(),
              SizedBox(height: 32.scale()), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    List<Flashcard> remainingCards,
    bool isMobile, {
    double maxCardWidth = 400,
  }) {
    // Calculate a dynamic height or use a constraint?
    // CardSwiper needs a height. If we want it to grow, we can try giving it a large height
    // but that breaks shorter cards.
    // Instead, we use AspectRatio or LayoutBuilder if needed.
    // BUT, simply removing Expanded makes it non-flexible.
    // Let's rely on a Container with a minimum height to ensure it's visible,
    // and let the content push it if the CardSwiper supports it.
    // However, typical CardSwiper implementations might need a finite height.
    // Let's try giving it a height based on screen size as a baseline (e.g. 60% of screen)
    // but allow scrolling if content overflows?
    // Wait, the user wants the card to be TALLER than screen if needed.
    // So we need an unconstrained height.
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      // Use a minimum height so short cards don't look collapsed
      constraints: BoxConstraints(minHeight: screenHeight * 0.5),
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              // Hack: CardSwiper requires height. If we want dynamic height,
              // we might have to measure content or give a very large height that fits in scroll view?
              // Actually, flutter_card_swiper takes the parent's size.
              // If parent is unconstrained (in a Column in a ScrollView), it errors.
              // So we MUST give a height.
              // Users request: "make the entire page scrollable and the flash can u become as long as required".
              // The only way to do this with CardSwiper is if we calculate the height of the current card's text.
              // Since we can't easily measure text before rendering, let's use a fixed large height
              // that is scrollable? No, too much whitespace.
              //
              // ALTERNATIVE: Use a LayoutBuilder to get width, then estimate height?
              // Let's try setting a Fixed height that is large enough (e.g. 600) but that defeats the purpose.
              //
              // Strategy: Use a very tall container for now? No.
              //
              // Check if `remainingCards` content is long.
              // Simplified Approach for this iteration:
              // Give it a height of `screenHeight * 0.75` for now.
              // If text is longer, it will clip?
              // The user SPECIFICALLY asked to avoid internal scrolling.
              //
              // Let's try to infer height from text length of top card.
              height: _calculateCardHeight(
                remainingCards.first.front,
                remainingCards.first.back,
                screenHeight,
              ),
              child: CardSwiper(
                key: ValueKey(
                  "${remainingCards.length}_${widget.state.isFlipped}",
                ), // Rebuild on flip to update disabled swipe state
                controller: _swiperController,
                cardsCount: remainingCards.length,
                numberOfCardsDisplayed: remainingCards.length.clamp(1, 3),
                backCardOffset: isMobile ? Offset(0, 45) : Offset(48, 38),
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
                          constraints: BoxConstraints(maxWidth: maxCardWidth),
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
                                                height: 64.r,
                                                width: 64.r,
                                                colorFilter: ColorFilter.mode(
                                                  Colors.white,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                "NAILED IT",
                                                style: TextStyle(
                                                  fontSize: 24,
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
                                                height: 64.h,
                                                width: 64.w,
                                                colorFilter: ColorFilter.mode(
                                                  Colors.white,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                "REVIEW",
                                                style: TextStyle(
                                                  fontSize: 24,
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
          ),
        ],
      ),
    );
  }

  double _calculateCardHeight(String front, String back, double screenHeight) {
    // Rough estimation logic
    // Base height for UI chrome (Header, prompt, spacing) ~ 200px
    // Font size 18, check length
    final text = widget.state.isFlipped ? back : front;
    // Avg chars per line ~ 30 for mobile width (safe estimate)
    // 18px height * 1.2 spacing = 21.6px per line

    final estLines = (text.length / 30).ceil();
    final textHeight = estLines * 28.0; // Increased line height buffer to 28

    final totalHeight =
        350 +
        textHeight; // Increased base buffer to 350 (header + footer + prompt)

    // Ensure at least screen height usage (minus header/progress)
    final minHeight = screenHeight * 0.6;

    return totalHeight > minHeight ? totalHeight : minHeight;
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

    return isMobile
        ? _buildMobileView(
            context,
            remainingCards,
            remainingCards.first,
            isMobile,
          )
        : _buildTabletView(
            context,
            remainingCards,
            remainingCards.first,
            isMobile,
          );
  }
}
