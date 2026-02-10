import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:recall/features/auth/presentation/widgets/cyberpunk_button.dart';
import 'package:recall/core/network/connectivity_cubit.dart';
import 'package:recall/core/widgets/loader.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, connectivityState) {
        final isOffline = connectivityState is ConnectivityOffline;
        final greenColor = isOffline
            ? const Color(0xFFFF0000)
            : const Color.fromARGB(255, 111, 138, 0);
        final statusColor = isOffline
            ? const Color(0xFFFF0000)
            : const Color.fromARGB(255, 142, 176, 8);

        return Scaffold(
          body: Stack(
            children: [
              // Background Grid
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridBackgroundPainter(color: greenColor),
                ),
              ),

              // Main Content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.0.scale(),
                              vertical: 16.0.scale(),
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Corners
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _CornerMarker(
                                      isTop: true,
                                      isLeft: true,
                                      color: greenColor,
                                    ),
                                    _CornerMarker(
                                      isTop: true,
                                      isLeft: false,
                                      color: greenColor,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 48.scale()),

                                // NET.VER Header
                                Row(
                                  children: [
                                    Container(
                                      width: 12.scale(),
                                      height: 12.scale(),
                                      color: const Color(
                                        0xFF666666,
                                      ), // Muted green/grey
                                    ),
                                    SizedBox(width: 8.scale()),
                                    Text(
                                      "NET.VER.2.04",
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        fontSize: 14.scale(),
                                        color: const Color(0xFFAAAAAA),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.scale()),

                                // RECALL Title
                                Text(
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
                                SizedBox(height: 8.scale()),

                                //SYSTEM BOOT
                                Stack(
                                  children: [
                                    Text(
                                      "//SYSTEM",
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: Colors
                                            .transparent, // Outline effect hack
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
                                Text(
                                  isOffline ? "OFFLINE" : "BOOT",
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
                                    Container(
                                      width: 4,
                                      height: 24,
                                      color: greenColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isOffline
                                          ? "CONNECTION LOST."
                                          : "AUTHENTICATION REQUIRED.",
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isOffline
                                          ? "NO CONNECTION"
                                          : "SECURE CONNECTION",
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        fontSize: 12,
                                        color: const Color(0xFF444444),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    Text(
                                      isOffline
                                          ? "OFFLINE MODE"
                                          : "ENCRYPTED [TLS 1.3]",
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        fontSize: 12,
                                        color: const Color(0xFF444444),
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
                                    if (!isOffline) ...[
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
                                    ] else
                                      Container(
                                        height: 2,
                                        width: double.infinity,
                                        color: Colors.red.withOpacity(0.3),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Login Button
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    if (state is AuthLoading) {
                                      return const Center(child: Loader());
                                    }
                                    return Opacity(
                                      opacity: isOffline ? 0.5 : 1.0,
                                      child: CyberpunkButton(
                                        text: "SIGN IN WITH GOOGLE",
                                        icon: const Icon(
                                          Icons.g_mobiledata,
                                          size: 32,
                                          color: Colors.black,
                                        ),
                                        onTap: isOffline
                                            ? () {}
                                            : () {
                                                context.read<AuthBloc>().add(
                                                  AuthLoginRequested(),
                                                );
                                              },
                                        width: double.infinity,
                                        height: 72,
                                      ),
                                    );
                                  },
                                ),

                                SizedBox(height: 64.scale()),
                                Container(
                                  height: 1,
                                  color: const Color(0xFF222222),
                                ),
                                SizedBox(height: 16.scale()),

                                // Footer
                                Row(
                                  children: [
                                    Text(
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
                                          margin: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          color: index == 2
                                              ? statusColor
                                              : const Color(0xFF333333),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.scale()),
                                Text(
                                  isOffline
                                      ? "OFFLINE // UNSTABLE"
                                      : "ONLINE // STABLE",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: greenColor,
                                    fontFamily: 'SpaceGrotesk',
                                    letterSpacing: 1,
                                  ),
                                ),

                                const Spacer(),

                                Center(
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
                                SizedBox(height: 16.scale()),

                                // Bottom Corners
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _CornerMarker(
                                      isTop: false,
                                      isLeft: true,
                                      color: greenColor,
                                    ),
                                    _CornerMarker(
                                      isTop: false,
                                      isLeft: false,
                                      color: greenColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  final Color color;

  _GridBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
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
  bool shouldRepaint(covariant _GridBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CornerMarker extends StatelessWidget {
  final bool isTop;
  final bool isLeft;
  final Color color;

  const _CornerMarker({
    required this.isTop,
    required this.isLeft,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.scale(),
      height: 24.scale(),
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 2) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 2) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: 2) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: 2) : BorderSide.none,
        ),
      ),
    );
  }
}
