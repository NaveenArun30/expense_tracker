import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });

    return const Scaffold(
      body: Center(child: Text("Expense Tracker", style: TextStyle(fontSize: 24))),
    );
  }
}
