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
import 'package:recall/injection_container.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:responsive_scaler/responsive_scaler.dart';

class DeckListPage extends StatefulWidget {
  const DeckListPage({super.key});

  @override
  State<DeckListPage> createState() => _DeckListPageState();
}

class _DeckListPageState extends State<DeckListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _deletionController;
  late Animation<double> _deletionAnimation;
  String? _animatingDeckId;

  @override
  void initState() {
    super.initState();
    _deletionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _deletionAnimation = CurvedAnimation(
      parent: _deletionController,
      curve: Curves.easeOut,
    );
    _deletionController.value = 1.0; // Start fully visible
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      sl<NotificationService>().initialize(authState.user.uid);
    }
  }

  @override
  void dispose() {
    _deletionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0.scale(), bottom: 4.scale()),
            child: SquareButton(
              icon: Icons.search,
              color: Colors.black,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.0.scale(), bottom: 4.scale()),
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
                vertical: 12.0.scale(),
                horizontal: 24.0.scale(),
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
                  SizedBox(height: 8.0.scale()),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.0.scale(),
                      vertical: 4.0.scale(),
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
                    return const SliverFillRemaining(
                      child: Center(child: Loader()),
                    );
                  } else if (state is DeckLoaded) {
                    if (state.decks.isEmpty) {
                      return SliverFillRemaining(child: _buildEmptyView());
                    }
                    return isOffline
                        ? _buildOfflineView()
                        : _buildDeckList(state, isMobile);
                  } else if (state is DeckError) {
                    final message = state.message.toLowerCase();
                    if (message.contains('connection') ||
                        message.contains('network') ||
                        message.contains('socket') ||
                        message.contains('offline') ||
                        message.contains('clientexception')) {
                      return _buildOfflineView();
                    }
                    return SliverFillRemaining(
                      child: Center(child: Text(state.message)),
                    );
                  }
                  return SliverFillRemaining(
                    child: Center(child: Text("Welcome to Recall")),
                  );
                },
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 30.0.scale())),
        ],
      ),

      floatingActionButton: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, state) {
          if (state is ConnectivityOffline) {
            return const SizedBox.shrink();
          }
          return Row(
            children: [
              const Spacer(),
              AnimatedButton(
                text: "NEW DECK",
                iconSide: "left",
                icon: Icons.add,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return CreateDeckDialog(
                        onSubmit: (topic, count, useImages, duration) {
                          context.read<DeckBloc>().add(
                            CreateDeck(
                              title: topic,
                              count: count,
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
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 600,
        mainAxisSpacing: 8.r,
        crossAxisSpacing: 8.r,
        childAspectRatio: isMobile ? 1.09 : 0.84,
      ),
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        final deck = state.decks[index];
        final isDeleting = deck.id == _animatingDeckId;

        return SizeTransition(
          sizeFactor: isDeleting
              ? _deletionAnimation
              : const AlwaysStoppedAnimation(1.0),
          child: DeckCard(
            deck: deck,
            onTap: () async {
              final deletedDeckId = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizPage(deck: deck)),
              );

              if (deletedDeckId != null && deletedDeckId is String) {
                // Trigger animation
                setState(() {
                  _animatingDeckId = deletedDeckId;
                });
                await _deletionController.reverse();

                // Then refresh data
                if (context.mounted) {
                  setState(() {
                    _animatingDeckId = null;
                    _deletionController.value = 1.0;
                  });
                  context.read<DeckBloc>().add(LoadDecks());
                }
              } else if (context.mounted) {
                // Normal return, just refresh
                context.read<DeckBloc>().add(LoadDecks());
              }
            },
            onDelete: () {
              _buildDeleteDialog(context, state, index);
            },
          ),
        );
      }, childCount: state.decks.length),
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
            spacing: 8.scale(),
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
              SizedBox(height: 12.scale()),
              Row(
                children: [
                  Expanded(
                    child: AnimatedButton(
                      text: "CANCEL",
                      color: Colors.white,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AnimatedButton(
                      text: "DELETE",
                      textColor: Colors.white,
                      color: Colors.red,
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
