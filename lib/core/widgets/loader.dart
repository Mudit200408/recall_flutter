import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class Loader extends StatelessWidget {
  final bool isGuest;
  const Loader({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 150.r,
        height: 150.r,
        child: Lottie.asset(
          isGuest
              ? 'assets/lottie/loading-local.json'
              : 'assets/lottie/loading-cloud.json',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
