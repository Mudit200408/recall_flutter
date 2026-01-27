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

  // Cache the widgets to prevent content switching mid-flip
  late Widget _currentFront;
  late Widget _currentBack;

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

    _currentFront = widget.front;
    _currentBack = widget.back;

    // Listen for animation completion to update content after a "flip back"
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          _currentFront = widget.front;
          _currentBack = widget.back;
        });
      }
    });

    // If starting flipped, set controller to end
    if (widget.isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        // Front -> Back
        // Update content immediately so we see the new back
        setState(() {
          _currentFront = widget.front;
          _currentBack = widget.back;
        });
        _controller.forward();
      } else {
        // Back -> Front (The Glitchy Case)
        // Keep the OLD back answer visible while we flip back to front
        setState(() {
          _currentBack = oldWidget.back; // KEEP OLD ANSWER
          _currentFront = widget.front; // NEW QUESTION (will be seen at end)
        });
        _controller.reverse();
      }
    } else {
      // Normal update (no flip change), just update content
      setState(() {
        _currentFront = widget.front;
        _currentBack = widget.back;
      });
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
            ..rotateY(angle), // Rotate around Y axis
          alignment: Alignment.center,
          child: isFrontVisible
              ? _currentFront
              : Transform(
                  // Fix mirrored text on the back
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _currentBack,
                ),
        );
      },
    );
  }
}
