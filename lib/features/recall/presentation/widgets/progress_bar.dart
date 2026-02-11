import 'package:flutter/material.dart';
import 'package:recall/features/recall/presentation/widgets/stripped_painter.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;
  const ProgressBar({super.key, required this.progress, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32.scale(),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: ClipRect(
        child: CustomPaint(
          painter: StripedProgressPainter(
            progress: progress,
            color: color ?? const Color(0xFFCCFF00),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
