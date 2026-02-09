import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class AnimatedButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final String? iconSide;
  final Color? color;
  final Color? textColor;
  const AnimatedButton({
    super.key,
    required this.text,
    this.icon,
    required this.onTap,
    this.iconSide,
    this.color,
    this.textColor,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
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
            ? Matrix4.translationValues(4, 4, 0)
            : Matrix4.identity(),
        height: 64.scale(),
        decoration: BoxDecoration(
          color: widget.color ?? const Color(0xFFCCFF00),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: _isPressed
              ? null
              : const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null && widget.iconSide == 'left')
              Icon(widget.icon!, color: Colors.black),
            SizedBox(width: 12.scale()),
            Text(
              widget.text,
              style: TextStyle(
                fontVariations: [FontVariation.weight(900)],
                fontSize: 18,
                color: widget.textColor ?? Colors.black,
              ),
            ),
            SizedBox(width: 12.scale()),
            if (widget.icon != null && widget.iconSide == 'right')
              Icon(widget.icon!, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
