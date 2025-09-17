import 'package:expense_tracker_app/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/theme_bloc/theme_bloc.dart';
import 'features/expenses/bloc/expense_bloc.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://tcfzmakxbsgnwrxjdlkj.supabase.co',
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjZnptYWt4YnNnbndyeGpkbGtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwMjEwNjEsImV4cCI6MjA3MzU5NzA2MX0.qycjm5idn5eO8lcbDPgyJLRwzZoaBMwp6SXTHQjgYB0",
  );
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeBloc()),
        BlocProvider(create: (_) => ExpenseBloc()),
        BlocProvider(create: (_) => AuthBloc()),
      ],
      child: const MyApp(),
    ),
  );
}
