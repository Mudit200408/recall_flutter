import 'dart:math';
import 'package:flutter/material.dart';

class FlipCardWidget extends StatefulWidget {
  final bool isFlipped;
  final Widget front;
  final Widget back;

  const FlipCardWidget({
    super.key,
    required this.isFlipped,
    required this.front,
    required this.back,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Smooth 0.6s flip
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when the parent (BLoC) changes the boolean
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate rotation (0 to 180 degrees)
        final angle = _animation.value * pi;
        
        // Is the front visible? (0 to 90 degrees)
        final isFrontVisible = angle < pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Add perspective (3D depth)
            ..rotateY(angle),       // Rotate around Y axis
          alignment: Alignment.center,
          child: isFrontVisible
              ? widget.front
              : Transform(
                  // Fix mirrored text on the back
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: widget.back,
                ),
        );
      },
    );
  }
}