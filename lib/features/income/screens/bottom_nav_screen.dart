import 'package:expense_tracker_app/constants/app_constants.dart';
import 'package:expense_tracker_app/features/expenses/screens/home_screen.dart';
import 'package:expense_tracker_app/features/income/screens/income_management.dart';
import 'package:expense_tracker_app/features/shared/screens/shared_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme_bloc/theme_bloc.dart';
import '../../expenses/bloc/expense_bloc.dart';
import '../../expenses/bloc/expense_event.dart';
import '../../settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationScreen({super.key, required this.navigationShell});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(LoadExpenses());
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  // Map nav-row tap index → page index (skip the centre ADD at tap-index 2)
  int _navIndexToPageIndex(int navIndex) {
    if (navIndex < 2) return navIndex;
    return navIndex - 1; // nav 3→page 2, nav 4→page 3
  }

  void _onNavTap(int navIndex) {
    if (navIndex == 2) {
      _openAddExpense();
      return;
    }
    widget.navigationShell.goBranch(_navIndexToPageIndex(navIndex));
  }

  Future<void> _openAddExpense() async {
    _fabAnimController.forward().then((_) => _fabAnimController.reverse());
    await context.push('/add-expense');
    if (mounted) context.read<ExpenseBloc>().add(RefreshExpenses());
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeBloc>();
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: widget.navigationShell,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isDark = AppConstants.isDark;
    final bgColor = isDark ? const Color(0xFF1A1B2E) : Colors.white;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.08);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                navIndex: 0,
                icon: Icons.grid_view_rounded,
                label: 'HOME',
              ),
              _buildNavItem(
                navIndex: 1,
                icon: Icons.account_balance_wallet_rounded,
                label: 'INCOME',
              ),
              _buildAddButton(),
              _buildNavItem(navIndex: 3, icon: Icons.group, label: 'SHARED'),
              _buildNavItem(
                navIndex: 4,
                icon: Icons.person_rounded,
                label: 'PROFILE',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int navIndex,
    required IconData icon,
    required String label,
  }) {
    final pageIndex = _navIndexToPageIndex(navIndex);
    final isSelected = widget.navigationShell.currentIndex == pageIndex;
    const accentColor = Color(0xFF8B5CF6);
    final inactiveColor = AppConstants.isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.35);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(navIndex),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? accentColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isSelected ? accentColor : inactiveColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final inactiveColor = AppConstants.isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.35);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(2),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 0.88).animate(
                CurvedAnimation(
                  parent: _fabAnimController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'ADD',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
