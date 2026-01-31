import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final int rating;
  final String assetName;
  final VoidCallback onPressed;
  const RatingButton({
    super.key,
    required this.label,
    required this.color,
    required this.rating,
    required this.assetName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // context.read<QuizBloc>().add(RateCard(rating: rating));
        // Logic moved to parent
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(assetName, height: 32, width: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
