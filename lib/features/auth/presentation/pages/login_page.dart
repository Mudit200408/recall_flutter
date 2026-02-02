import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:recall/features/auth/presentation/widgets/cyberpunk_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    const greenColor = Color.fromARGB(255, 111, 138, 0);
    return Scaffold(
      backgroundColor: Colors.white, // Dark dark grey
      body: Stack(
        children: [
          // Background Grid
          Positioned.fill(
            child: CustomPaint(painter: _GridBackgroundPainter()),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Corners
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CornerMarker(isTop: true, isLeft: true),
                      _CornerMarker(isTop: true, isLeft: false),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // NET.VER Header
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: const Color(0xFF666666), // Muted green/grey
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "NET.VER.2.04",
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 14,
                          color: const Color(0xFFAAAAAA),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // RECALL Title
                  const Text(
                    "RECALL",
                    style: TextStyle(
                      fontFamily: 'ArchivoBlack',
                      fontSize: 64,
                      color: Color.fromARGB(255, 223, 223, 223),
                      height: 0.9,
                      letterSpacing: -2,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // //SYSTEM BOOT
                  Stack(
                    children: [
                      Text(
                        "//SYSTEM",
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.transparent, // Outline effect hack
                          letterSpacing: -1,
                          height: 0.9,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(
                              offset: Offset(-1, -1),
                              color: Color(0xFF666666),
                            ),
                            Shadow(
                              offset: Offset(1, -1),
                              color: Color(0xFF666666),
                            ),
                            Shadow(
                              offset: Offset(1, 1),
                              color: Color(0xFF666666),
                            ),
                            Shadow(
                              offset: Offset(-1, 1),
                              color: Color(0xFF666666),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        "//SYSTEM",
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white, // Match bg
                          letterSpacing: -1,
                          height: 0.9,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    "BOOT",
                    style: TextStyle(
                      fontFamily: 'ArchivoBlack',
                      fontSize: 64,
                      color: Color.fromARGB(255, 70, 70, 70),
                      height: 0.9,
                      letterSpacing: -2,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Auth Required Banner
                  Row(
                    children: [
                      Container(width: 4, height: 24, color: greenColor),
                      const SizedBox(width: 12),
                      Text(
                        "AUTHENTICATION REQUIRED.",
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 16,
                          color: greenColor,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Connection Status
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "SECURE CONNECTION",
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12,
                          color: Color(0xFF444444),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "ENCRYPTED [TLS 1.3]",
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12,
                          color: Color(0xFF444444),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Divider line with progress bar
                  Stack(
                    children: [
                      Container(
                        height: 2,
                        width: double.infinity,
                        color: const Color(0xFF222222),
                      ),
                      Container(
                        height: 2,
                        width: 100, // Partial progress
                        color: const Color(0xFF333300),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 2,
                          width: 100,
                          color: const Color(0xFF445500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  CyberpunkButton(
                    text: "SIGN IN WITH GOOGLE",
                    icon: const Icon(
                      Icons.g_mobiledata,
                      size: 32,
                      color: Colors.black,
                    ), // Using G icon surrogate
                    onTap: () {
                      context.read<AuthBloc>().add(AuthLoginRequested());
                    },
                    width: double.infinity,
                    height: 72,
                  ),

                  const SizedBox(height: 64),
                  Container(height: 1, color: const Color(0xFF222222)),
                  const SizedBox(height: 16),

                  // Footer
                  Row(
                    children: [
                      const Text(
                        "SYSTEM STATUS",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF444444),
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      const Spacer(),
                      // Status indicators
                      Row(
                        children: List.generate(
                          3,
                          (index) => Container(
                            width: 6,
                            height: 12,
                            margin: const EdgeInsets.only(left: 4),
                            color: index == 2
                                ? const Color.fromARGB(255, 142, 176, 8)
                                : const Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "ONLINE // STABLE",
                    style: TextStyle(
                      fontSize: 12,
                      color: greenColor,
                      fontFamily: 'SpaceGrotesk',
                      letterSpacing: 1,
                    ),
                  ),

                  const Spacer(),

                  const Center(
                    child: Text(
                      "UNAUTHORIZED ACCESS IS A\nCLASS A FELONY UNDER CORP LAW 404.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 10,
                        color: Color(0xFF333333),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Corners
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CornerMarker(isTop: false, isLeft: true),
                      _CornerMarker(isTop: false, isLeft: false),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 111, 137, 6).withOpacity(0.05)
      ..strokeWidth = 1;

    const double spacing = 20.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw tiny plus or dot
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerMarker extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerMarker({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    const greenColor = Color.fromARGB(255, 149, 186, 3);

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: greenColor, width: 2)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: greenColor, width: 2)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: greenColor, width: 2)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: greenColor, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }
}
