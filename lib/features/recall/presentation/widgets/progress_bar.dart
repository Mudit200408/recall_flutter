import 'package:flutter/material.dart';
import 'package:recall/core/theme/app_colors.dart';
import 'package:recall/features/recall/presentation/widgets/stripped_painter.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;
  final bool isGuest;
  const ProgressBar({super.key, required this.progress, this.color, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32.h,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: ClipRect(
        child: CustomPaint(
          painter: StripedProgressPainter(
            progress: progress,
            color: color ?? accentColor(isGuest),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
