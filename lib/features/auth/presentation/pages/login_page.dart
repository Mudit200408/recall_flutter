import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            // Logo / Branding
            const Icon(Icons.psychology, size: 100, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text(
              "Recall",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Master your studies with AI",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.login,
                ), // You can use a Google Icon asset here later
                label: const Text("Continue with Google"),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLoginRequested());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
