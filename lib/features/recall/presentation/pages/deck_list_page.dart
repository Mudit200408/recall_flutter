import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/network/connectivity_cubit.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/core/widgets/loader.dart';
import 'package:recall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:recall/features/recall/presentation/bloc/deck/deck_bloc.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';
import 'package:recall/features/recall/presentation/widgets/create_deck_dialog.dart';
import 'package:recall/features/recall/presentation/widgets/deck_card.dart';
import 'package:recall/features/recall/presentation/widgets/square_button.dart';
import 'package:recall/features/recall/presentation/pages/offline_view.dart';
import 'package:recall/features/recall/presentation/pages/quiz_page.dart';
import 'package:recall/features/recall/presentation/pages/search_page.dart';
import 'package:recall/features/recall/presentation/pages/model_selection_page.dart';
import 'package:recall/injection_container.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:responsive_scaler/responsive_scaler.dart';

class DeckListPage extends StatefulWidget {
  final bool isGuest;
  const DeckListPage({super.key, required this.isGuest});

  @override
  State<DeckListPage> createState() => _DeckListPageState();
}

class _DeckListPageState extends State<DeckListPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      sl<NotificationService>().initialize(authState.user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0.r, bottom: 4.r),
            child: SquareButton(
              icon: Icons.search,
              color: Colors.black,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchPage(isGuest: widget.isGuest),
                  ),
                );
              },
            ),
          ),
          if (context.read<AuthBloc>().state is AuthGuest)
            Padding(
              padding: EdgeInsets.only(right: 8.0.r, bottom: 4.r),
              child: SquareButton(
                icon: Icons.psychology,
                color: Colors.black,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ModelSelectionPage(isSettingsMode: false),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: EdgeInsets.only(right: 8.0.r, bottom: 4.r),
            child: SquareButton(
              icon: Icons.logout,
              color: const Color.fromARGB(255, 255, 17, 0),
              onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: Colors.black, height: 4),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 12.0.r,
                horizontal: 24.0.r,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RECALL",
                    style: TextStyle(
                      fontSize: 52,
                      letterSpacing: 4,
                      color: Colors.black,
                      height: 1.0,
                      fontFamily: "ArchivoBlack",
                    ),
                  ),
                  SizedBox(height: 8.0.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.0.r,
                      vertical: 4.0.r,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "MASTER YOUR MIND",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectivityState) {
              final isMobile = ResponsiveBreakpoints.of(context).isMobile;
              final isOffline = connectivityState is ConnectivityOffline;
              return BlocBuilder<DeckBloc, DeckState>(
                builder: (context, state) {
                  if (state is DeckLoading) {
                    return SliverFillRemaining(
                      child: Center(child: Loader(isGuest: widget.isGuest)),
                    );
                  } else if (state is DeckLoaded) {
                    if (state.decks.isEmpty) {
                      return SliverFillRemaining(child: _buildEmptyView());
                    }
                    return isOffline && !widget.isGuest
                        ? _buildOfflineView()
                        : _buildDeckList(state, isMobile);
                  } else if (state is DeckError) {
                    final message = state.message.toLowerCase();
                    if (!widget.isGuest &&
                        (message.contains('connection') ||
                            message.contains('network') ||
                            message.contains('socket') ||
                            message.contains('offline') ||
                            message.contains('clientexception'))) {
                      return _buildOfflineView();
                    }
                    return SliverFillRemaining(
                      child: Center(child: Text(state.message)),
                    );
                  }
                  return SliverFillRemaining(
                    child: Center(child: Loader(isGuest: widget.isGuest)),
                  );
                },
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 60.0.h)),
        ],
      ),

      floatingActionButton: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, state) {
          if (state is ConnectivityOffline && !widget.isGuest) {
            return const SizedBox.shrink();
          }
          return Row(
            children: [
              const Spacer(),
              AnimatedButton(
                text: "NEW DECK",
                iconSide: "left",
                icon: Icons.add,
                isGuest: widget.isGuest,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return CreateDeckDialog(
                        isGuest: context.read<AuthBloc>().state is AuthGuest,
                        onSubmit:
                            (
                              topic,
                              count,
                              difficultyLevel,
                              useImages,
                              duration,
                            ) {
                              context.read<DeckBloc>().add(
                                CreateDeck(
                                  title: topic,
                                  count: count,
                                  difficultyLevel: difficultyLevel,
                                  useImages: useImages,
                                  duration: duration,
                                ),
                              );
                            },
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeckList(DeckLoaded state, bool isMobile) {
    // Calculate columns based on width (maxCrossAxisExtent logic equivalent)
    final width = MediaQuery.sizeOf(context).width;
    final int crossAxisCount = (width / 600).ceil();
    final int rowCount = (state.decks.length / crossAxisCount).ceil();

    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        final int startIndex = index * crossAxisCount;
        final int endIndex = (startIndex + crossAxisCount < state.decks.length)
            ? startIndex + crossAxisCount
            : state.decks.length;

        final rowDecks = state.decks.sublist(startIndex, endIndex);

        return Padding(
          padding: EdgeInsets.only(bottom: 8.r),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...rowDecks.map((deck) {
                  final int deckIndex = state.decks.indexOf(deck);
                  // Add spacing between items (except the last one in the row)
                  final isLastSlot =
                      rowDecks.indexOf(deck) == crossAxisCount - 1;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: isLastSlot ? 0 : 8.r),
                      child: DeckCard(
                        isGuest: widget.isGuest,
                        deck: deck,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuizPage(deck: deck, isGuest: widget.isGuest),
                            ),
                          );
                          if (context.mounted) {
                            context.read<DeckBloc>().add(LoadDecks());
                          }
                        },
                        onDelete: () {
                          _buildDeleteDialog(context, state, deckIndex);
                        },
                      ),
                    ),
                  );
                }),
                // Fill remaining space with empty widgets to maintain alignment
                if (rowDecks.length < crossAxisCount)
                  ...List.generate(crossAxisCount - rowDecks.length, (index) {
                    final isLastSlot =
                        (rowDecks.length + index) == crossAxisCount - 1;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: isLastSlot ? 0 : 8.r),
                        child: const SizedBox(),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      }, childCount: rowCount),
    );
  }

  Widget _buildOfflineView() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: OfflineView(
        onRetry: () {
          // Trigger a reload or connectivity check
          context.read<DeckBloc>().add(LoadDecks());
        },
      ),
    );
  }

  Widget _buildEmptyView() => Center(
    child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/question-mark.png', height: 300),
          Text(
            "NULL_DATA",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'ArchivoBlack',
            ),
          ),
          Text(
            "CREATE A DECK TO START YOUR MISSION",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    ),
  );

  Future<dynamic> _buildDeleteDialog(
    BuildContext context,
    DeckLoaded state,
    int index,
  ) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 4),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(4, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: .start,
            spacing: 8.r,
            children: [
              Text(
                "DELETE DECK?",
                style: TextStyle(
                  fontSize: 24,
                  fontVariations: [FontVariation.weight(900)],
                ),
              ),
              Text(
                "WARNING: This action cannot be undone.",
                style: TextStyle(
                  fontSize: 16,
                  fontVariations: [FontVariation.weight(900)],
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: AnimatedButton(
                      text: "CANCEL",
                      color: Colors.white,
                      onTap: () => Navigator.pop(context),
                      isGuest: widget.isGuest,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AnimatedButton(
                      text: "DELETE",
                      textColor: Colors.white,
                      color: Colors.red,
                      isGuest: widget.isGuest,
                      onTap: () {
                        context.read<DeckBloc>().add(
                          DeleteDeck(deckId: state.decks[index].id),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
