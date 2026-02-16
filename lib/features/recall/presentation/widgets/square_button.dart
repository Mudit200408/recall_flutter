import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class SquareButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const SquareButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  State<SquareButton> createState() => _SquareButtonState();
}

class _SquareButtonState extends State<SquareButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        transform: _isPressed
            ? Matrix4.translationValues(3, 3, 0)
            : Matrix4.identity(),

        height: 45.h,
        width: 45.w,

        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: widget.color, width: 3),
          boxShadow: _isPressed
              ? null
              : [BoxShadow(color: widget.color, offset: Offset(3, 3))],
        ),
        child: Icon(widget.icon, color: widget.color, weight: 700),
      ),
    );
  }
}
