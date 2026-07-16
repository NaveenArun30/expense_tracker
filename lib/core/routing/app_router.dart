import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker_app/splash_screen.dart';
import 'package:expense_tracker_app/features/auth/screens/login_screen.dart';
import 'package:expense_tracker_app/features/auth/screens/register_screen.dart';
import 'package:expense_tracker_app/features/auth/screens/biometric_auth_screen.dart';
import 'package:expense_tracker_app/features/income/screens/bottom_nav_screen.dart';
import 'package:expense_tracker_app/features/expenses/screens/add_expense_screen.dart';
import 'package:expense_tracker_app/features/ai/screens/ai_chat_screen.dart';
import 'package:expense_tracker_app/features/expenses/screens/analytics_screen.dart';
import 'package:expense_tracker_app/features/expenses/screens/expense_log_screen.dart';
import 'package:expense_tracker_app/features/settings/security_settings_screen.dart';
import 'package:expense_tracker_app/features/settings/budget_settings_screen.dart';
import 'package:expense_tracker_app/features/income/screens/add_income_screen.dart';
import 'package:expense_tracker_app/features/income/screens/add_account_screen.dart';
import 'package:expense_tracker_app/features/shared/screens/group_detail_screen.dart';
import 'package:expense_tracker_app/features/shared/screens/add_shared_expense_screen.dart';
import 'package:expense_tracker_app/features/shared/screens/shared_expense_detail_screen.dart';
import 'package:expense_tracker_app/features/expenses/screens/home_screen.dart';
import 'package:expense_tracker_app/features/income/screens/income_management.dart';
import 'package:expense_tracker_app/features/shared/screens/shared_dashboard_screen.dart';
import 'package:expense_tracker_app/features/settings/settings_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/main',
      redirect: (context, state) => '/home',
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/income',
              name: 'income',
              builder: (context, state) => const IncomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shared',
              name: 'shared',
              builder: (context, state) => const SharedDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/add-expense',
      name: 'add-expense',
      builder: (context, state) => const AddExpenseScreen(),
    ),
    GoRoute(
      path: '/ai-chat',
      name: 'ai-chat',
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/expense-log',
      name: 'expense-log',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final selectedMonth = extra?['selectedMonth'] as DateTime?;
        final selectedDateRange = extra?['selectedDateRange'] as DateTimeRange?;
        return ExpenseLogScreen(
          selectedMonth: selectedMonth,
          selectedDateRange: selectedDateRange,
        );
      },
    ),
    GoRoute(
      path: '/security-settings',
      name: 'security-settings',
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: '/budget-settings',
      name: 'budget-settings',
      builder: (context, state) => const BudgetSettingsScreen(),
    ),
    GoRoute(
      path: '/add-income',
      name: 'add-income',
      builder: (context, state) => const AddIncomeScreen(),
    ),
    GoRoute(
      path: '/add-account',
      name: 'add-account',
      builder: (context, state) => const AddAccountScreen(),
    ),
    GoRoute(
      path: '/group-detail/:groupId',
      name: 'group-detail',
      builder: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        return GroupDetailScreen(groupId: groupId);
      },
    ),
    GoRoute(
      path: '/group-detail/:groupId/add-shared-expense',
      name: 'add-shared-expense',
      builder: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        return AddSharedExpenseScreen(groupId: groupId);
      },
    ),
    GoRoute(
      path: '/shared-expense-detail/:expenseId',
      name: 'shared-expense-detail',
      builder: (context, state) {
        final expenseId = state.pathParameters['expenseId']!;
        return SharedExpenseDetailScreen(expenseId: expenseId);
      },
    ),
    GoRoute(
      path: '/biometric-auth',
      name: 'biometric-auth',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final onAuthenticated = extra?['onAuthenticated'] as VoidCallback;
        return BiometricAuthScreen(onAuthenticated: onAuthenticated);
      },
    ),
  ],
);
