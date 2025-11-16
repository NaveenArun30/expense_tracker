import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker_app/features/auth/bloc/auth_bloc.dart';
import 'package:expense_tracker_app/features/auth/bloc/auth_state.dart';
import 'package:expense_tracker_app/features/auth/bloc/auth_event.dart';
import 'package:expense_tracker_app/features/auth/screens/login_screen.dart';
import 'package:expense_tracker_app/features/expenses/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Dispatch the CheckAuthStatus event after build context is available
    Future.microtask(() {
      context.read<AuthBloc>().add(CheckAuthStatus());

      // Wait a little before navigating based on the state
      Future.delayed(const Duration(seconds: 2), () {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Expense Tracker", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
