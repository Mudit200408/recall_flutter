import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CyberpunkButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Widget? icon;
  final double width;
  final double height;

  const CyberpunkButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.width = double.infinity,
    this.height = 64,
  });

  @override
  State<CyberpunkButton> createState() => _CyberpunkButtonState();
}

class _CyberpunkButtonState extends State<CyberpunkButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: Stack(
        children: [
          // Background Shadow (Hard offset)
          if (!_isPressed)
            Positioned(
              left: 6,
              top: 6,
              right: 0,
              bottom: 0,
              child: Container(color: Colors.black),
            ),

          // Main Button Container
          AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: widget.width,
            height: widget.height,
            margin: _isPressed
                ? const EdgeInsets.only(left: 6, top: 6)
                : const EdgeInsets.only(right: 6, bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFCCFF00), // Lime Green
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Stack(
              children: [
                // Scanline Pattern
                Positioned.fill(
                  child: CustomPaint(painter: _ScanlinePainter()),
                ),

                // Corner Brackets
                const Positioned(
                  left: 4,
                  top: 4,
                  child: _CornerBracket(isTop: true, isLeft: true),
                ),
                const Positioned(
                  right: 4,
                  top: 4,
                  child: _CornerBracket(isTop: true, isLeft: false),
                ),
                const Positioned(
                  left: 4,
                  bottom: 4,
                  child: _CornerBracket(isTop: false, isLeft: true),
                ),
                const Positioned(
                  right: 4,
                  bottom: 4,
                  child: _CornerBracket(isTop: false, isLeft: false),
                ),

                // Content
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 12),
                      ],
                      Text(
                        widget.text.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha:0.05)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerBracket extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerBracket({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }
}
