import 'package:expense_tracker_app/core/theme_bloc/theme_state.dart'
    show ThemeState;
import 'package:expense_tracker_app/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme_bloc/theme_bloc.dart';
import 'constants/app_constants.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        // Set the global isDark flag in AppConstants so that color getters resolve correctly.
        AppConstants.isDark = themeState.isDark;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeState.isDark
              ? ThemeData.dark().copyWith(
                  scaffoldBackgroundColor: const Color(0xFF0C0D14),
                  cardColor: const Color(0xFF161722),
                  dialogBackgroundColor: const Color(0xFF161722),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF0C0D14),
                    elevation: 0,
                  ),
                )
              : ThemeData.light().copyWith(
                  scaffoldBackgroundColor: const Color(0xFFF8F9FA),
                  cardColor: const Color(0xFFFFFFFF),
                ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
