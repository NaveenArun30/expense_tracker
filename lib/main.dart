import 'package:expense_tracker_app/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/theme_bloc/theme_bloc.dart';
import 'features/expenses/bloc/expense_bloc.dart';
import 'features/income/bloc/income_bloc.dart';
import 'features/ai/bloc/ai_bloc.dart';
import 'services/ai_service.dart';
import 'services/preferences_service.dart';
import 'services/security_service.dart';
import 'features/auth/screens/biometric_auth_screen.dart';
import 'features/shared/repositories/shared_repository.dart';
import 'features/shared/bloc/shared_bloc.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://tcfzmakxbsgnwrxjdlkj.supabase.co',
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjZnptYWt4YnNnbndyeGpkbGtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwMjEwNjEsImV4cCI6MjA3MzU5NzA2MX0.qycjm5idn5eO8lcbDPgyJLRwzZoaBMwp6SXTHQjgYB0",
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => PreferencesService()),
        RepositoryProvider(create: (_) => AiService()),
        RepositoryProvider(create: (_) => SecurityService()),
        RepositoryProvider(create: (_) => SharedRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeBloc()),
          BlocProvider(create: (_) => ExpenseBloc()),
          BlocProvider(create: (_) => AuthBloc()),
          BlocProvider(create: (_) => IncomeBloc()),
          BlocProvider(
            create: (context) => AiBloc(
              aiService: context.read<AiService>(),
              preferencesService: context.read<PreferencesService>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                SharedBloc(repository: context.read<SharedRepository>()),
          ),
        ],
        child: const AppLifecycleManager(child: MyApp()),
      ),
    ),
  );
}

class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final securityService = context.read<SecurityService>();

    if (state == AppLifecycleState.paused) {
      securityService.updateActivity();
    } else if (state == AppLifecycleState.resumed) {
      if (securityService.shouldLock()) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BiometricAuthScreen(
              onAuthenticated: () {
                securityService.setAuthenticated(true);
                Navigator.of(context).pop();
              },
            ),
            fullscreenDialog: true,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
