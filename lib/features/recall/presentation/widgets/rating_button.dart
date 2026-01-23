import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/features/recall/presentation/bloc/quiz/quiz_bloc.dart';

class RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final int rating;
  const RatingButton({
    super.key,
    required this.label,
    required this.color,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        context.read<QuizBloc>().add(RateCard(rating: rating));
      },
      child: Text(label),
    );
  }
}
