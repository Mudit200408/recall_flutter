import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 100.r,
        height: 100.r,
        child: Lottie.asset('assets/lottie/loading.json', fit: BoxFit.contain),
      ),
    );
  }
}
