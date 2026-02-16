import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class OfflineView extends StatelessWidget {
  const OfflineView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,

      child: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Robot Illustration Container
                      SizedBox(
                        width: 256.w,
                        height: 256.h,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Yellow background rect
                            Transform.translate(
                              offset: const Offset(8, 8),
                              child: Transform.rotate(
                                angle: 6 * 3.14159 / 180,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[300],
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // White foreground rect with SVG
                            Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: SvgPicture.string(
                                '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
<rect fill="#e5e7eb" height="60" rx="4" stroke="black" stroke-width="4" width="80" x="60" y="40"></rect>
<line stroke="black" stroke-width="3" x1="100" x2="100" y1="40" y2="20"></line>
<circle cx="100" cy="15" fill="#ff2a9d" r="5" stroke="black" stroke-width="3"></circle>
<line stroke="black" stroke-width="3" x1="75" x2="85" y1="60" y2="70"></line>
<line stroke="black" stroke-width="3" x1="85" x2="75" y1="60" y2="70"></line>
<line stroke="black" stroke-width="3" x1="115" x2="125" y1="60" y2="70"></line>
<line stroke="black" stroke-width="3" x1="125" x2="115" y1="60" y2="70"></line>
<path d="M 80 85 Q 100 75 120 85" fill="none" stroke="black" stroke-width="3"></path>
<g transform="rotate(15, 100, 150)">
<rect fill="#e5e7eb" height="70" stroke="black" stroke-width="4" width="60" x="70" y="110"></rect>
<circle cx="90" cy="130" fill="black" r="4"></circle>
<circle cx="110" cy="130" fill="black" r="4"></circle>
<rect fill="black" height="10" width="30" x="85" y="150"></rect>
</g>
<path d="M 60 120 Q 40 100 50 80" fill="none" stroke="black" stroke-width="4"></path>
<path d="M 140 130 Q 160 110 150 90" fill="none" stroke="black" stroke-width="4"></path>
<path d="M 20 190 Q 80 160 100 190 Q 140 210 180 180" fill="none" stroke="black" stroke-dasharray="8 4" stroke-width="4"></path>
<path d="M 160 30 L 170 10 L 160 20 L 180 20 L 165 30 Z" fill="#ff2a9d" stroke="black" stroke-width="2"></path>
</svg>''',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Title
                      Text(
                        "YOU ARE\nOFFLINE",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          height: 0.85,
                          letterSpacing: -1.0,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Badge
                      Transform.rotate(
                        angle: -2 * 3.14159 / 180,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          color: Colors.black,
                          child: const Text(
                            "The internet is in another castle.",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily:
                                  'monospace', // Fallback as Share Tech Mono is missing
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 21.r),
                        child: AnimatedButton(
                          color: const Color(0xFFff2a9d),
                          text: 'RETRY',
                          onTap: onRetry,
                          icon: Icons.videogame_asset,
                          iconSide: 'left',
                          isGuest: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          Colors.grey[300]! // #d1d5db
      ..style = PaintingStyle.fill;

    const double spacing = 20.0;
    const double radius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
