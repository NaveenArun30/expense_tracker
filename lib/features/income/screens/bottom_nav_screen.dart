import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:expense_tracker_app/constants/app_constants.dart';
import 'package:expense_tracker_app/features/expenses/screens/home_screen.dart';
import 'package:expense_tracker_app/features/income/screens/income_management.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../expenses/bloc/expense_bloc.dart';
import '../../expenses/bloc/expense_event.dart';
import '../../settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const HomeScreen(),
    const IncomeScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(LoadExpenses());

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: CubertoBottomBar(
        key: const Key("BottomBar"),
        inactiveIconColor: Colors.grey.shade400,
        tabStyle: CubertoTabStyle.styleNormal,
        selectedTab: _currentPage,
        tabs: [
          TabData(
            key: const Key("Expenses"),
            iconData: Icons.receipt_long_rounded,
            title: "Expenses",
            tabColor: AppConstants.primaryColor,
            tabGradient: LinearGradient(
              colors: AppConstants.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          TabData(
            key: const Key("Income"),
            iconData: Icons.trending_up_rounded,
            title: "Income",
            tabColor: AppConstants.successColor,
            tabGradient: LinearGradient(
              colors: [
                AppConstants.successColor,
                AppConstants.successColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          TabData(
            key: const Key("Profile"),
            iconData: Icons.person_rounded,
            title: "Profile",
            tabColor: const Color(0xFF667eea),
            tabGradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
        onTabChangedListener: (position, title, color) {
          setState(() {
            _currentPage = position;
          });
          _pageController.animateToPage(
            position,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
