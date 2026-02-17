import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class FuturisticSwipeOverlay extends StatelessWidget {
  final Color baseColor;
  final String svgPath;
  final String label;
  final double swipePercentage; // 0.0 to 1.0
  final bool isRightSwipe;

  const FuturisticSwipeOverlay({
    super.key,
    required this.baseColor,
    required this.svgPath,
    required this.label,
    required this.swipePercentage,
    required this.isRightSwipe,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = swipePercentage.abs().clamp(0.0, 1.0);
    final contentColor = isRightSwipe ? Colors.black : Colors.white;

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Container(
            // Neo-Brutalist Solid Background
            decoration: BoxDecoration(
              color: baseColor,
              // Adding a thick black border for that raw brutalist feel
              border: Border.all(color: Colors.black, width: 6),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    svgPath,
                    height: 80.r,
                    width: 80.r,
                    colorFilter: ColorFilter.mode(
                      contentColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontVariations: [FontVariation.weight(900)],
                      color: contentColor,
                      letterSpacing: 4,
                      fontStyle:
                          FontStyle.italic, // Italicized for "gaming speed"
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
