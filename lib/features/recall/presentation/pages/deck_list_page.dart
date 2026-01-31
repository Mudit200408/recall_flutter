import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:recall/features/recall/presentation/bloc/deck/deck_bloc.dart';
import 'package:recall/features/recall/presentation/widgets/create_deck_dialog.dart';
import 'package:recall/features/recall/presentation/widgets/deck_card.dart';
import 'package:recall/features/recall/presentation/pages/quiz_page.dart';
import 'package:recall/injection_container.dart';

class DeckListPage extends StatefulWidget {
  const DeckListPage({super.key});

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
        title: const Text("My Decks"),
        actions: [
          IconButton(
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocBuilder<DeckBloc, DeckState>(
        builder: (context, state) {
          if (state is DeckLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DeckLoaded) {
            if (state.decks.isEmpty) {
              return const Center(child: Text("No decks yet. Create one!"));
            }
            return ListView.builder(
              itemCount: state.decks.length,
              itemBuilder: (context, index) {
                return DeckCard(
                  deck: state.decks[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizPage(deck: state.decks[index]),
                      ),
                    );
                  },
                  onEdit: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Edit feature coming soon!"),
                      ),
                    );
                  },
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Delete Deck"),
                          content: const Text("This action cannot be undone."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<DeckBloc>().add(
                                  DeleteDeck(deckId: state.decks[index].id),
                                );
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          } else if (state is DeckError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text("Welcome to Recall"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return CreateDeckDialog(
                onSubmit: (topic, count, useImages) {
                  context.read<DeckBloc>().add(
                    CreateDeck(
                      title: topic,
                      count: count,
                      useImages: useImages,
                    ),
                  );
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
