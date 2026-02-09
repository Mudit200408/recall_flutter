import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class RatingButton extends StatefulWidget {
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
  State<RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<RatingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 100.scale()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: _isPressed
              ? Matrix4.translationValues(4, 4, 0)
              : Matrix4.identity(),
          padding: EdgeInsets.all(18.scale()),
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: _isPressed
                ? null
                : [
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
              SvgPicture.asset(widget.assetName, height: 32, width: 32),
              SizedBox(height: 8.scale()),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16.scale(),
                  fontVariations: [FontVariation.weight(900)],
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
