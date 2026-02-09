import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/features/recall/presentation/bloc/deck/deck_bloc.dart';
import 'package:recall/features/recall/presentation/pages/quiz_page.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';
import 'package:recall/features/recall/presentation/widgets/deck_card.dart';
import 'package:recall/features/recall/presentation/widgets/square_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: EdgeInsets.all(8.0.scale()),
          child: SquareButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
            color: Colors.black,
          ),
        ),
        title: Text(
          'SEARCH OBJECTIVES',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(4),
        //   child: Container(color: Colors.black, height: 4),
        // ),
      ),
      body: Column(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0.scale()),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                    ],
                  ),
                  child: TextField(
                    autofocus: true,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.scale(),
                    ),
                    decoration: InputDecoration(
                      hintText: 'SEARCH DECKS...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      suffixIcon: Icon(Icons.search, color: Colors.black),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                  ),
                ),
              ),
              const Divider(color: Colors.black, thickness: 2),
            ],
          ),
          Expanded(
            child: BlocBuilder<DeckBloc, DeckState>(
              builder: (context, state) {
                if (state is DeckLoaded) {
                  final filteredDecks = state.decks.where((deck) {
                    return deck.title.toLowerCase().contains(
                      _query.toLowerCase(),
                    );
                  }).toList();

                  if (filteredDecks.isEmpty) {
                    return Center(
                      child: Text(
                        "NO DECKS FOUND",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  final isMobile = ResponsiveBreakpoints.of(context).isMobile;
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.all(16.scale()),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 800,
                                mainAxisSpacing: 8.scale(),
                                crossAxisSpacing: 8.scale(),
                                childAspectRatio: isMobile ? 1 : 0.8,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final deck = filteredDecks[index];
                            return DeckCard(
                              deck: deck,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuizPage(deck: deck),
                                  ),
                                );
                              },
                              onDelete: () =>
                                  _buildDeleteDialog(context, state, index),
                            );
                          }, childCount: filteredDecks.length),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

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
          padding: EdgeInsets.all(12.scale()),
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
            mainAxisAlignment: MainAxisAlignment.start,
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
                  SizedBox(width: 12.scale()),
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
