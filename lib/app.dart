import 'package:expense_tracker_app/core/theme_bloc/theme_state.dart'
    show ThemeState;
import 'package:expense_tracker_app/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme_bloc/theme_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeState.isDark ? ThemeData.dark() : ThemeData.light(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
