import 'package:expense_tracker_app/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/monthly_expense_widget.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../reports/screens/report_screen.dart';
import '../../settings/settings_screen.dart';
import '../../settings/budget_settings_screen.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';
import 'expense_log_screen.dart';
import '../../../widgets/date_picker_widget.dart';
import '../../../core/currency_bloc/currency_cubit.dart';
import '../../../core/budget_bloc/budget_cubit.dart';
import '../../../core/budget_bloc/budget_state.dart';
import '../../../model/expense_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _dateFilterLabel = DateFormat.MMM().format(DateTime.now());
  DateTime? _selectedMonth = DateTime.now();
  DateTimeRange? _selectedDateRange;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
          ),
        );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(child: DashboardShimmerWidget()),
              ],
            );
          }

          if (state is ExpenseLoaded) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          _buildBalanceCard(state),
                          const SizedBox(height: 16),
                          _buildQuickStats(state),
                          const SizedBox(height: 16),
                          _buildBudgetModule(state),
                          const SizedBox(height: 16),
                          _buildCategoriesCard(state),
                          const SizedBox(height: 16),
                          _buildActionCards(context, state),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    String greeting = "GOOD MORNING";
    final hour = DateTime.now().hour;
    if (hour >= 12 && hour < 17) {
      greeting = "GOOD AFTERNOON";
    } else if (hour >= 17 || hour < 4) {
      greeting = "GOOD EVENING";
    }

    String userName = "USER";
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      if (authState.userMetadata != null &&
          authState.userMetadata!['name'] != null) {
        userName = authState.userMetadata!['name'].toString().toUpperCase();
      } else {
        userName = authState.email.split('@')[0].toUpperCase();
      }
    }

    return SliverAppBar(
      backgroundColor: AppConstants.backgroundColor,
      elevation: 0,
      pinned: true,
      floating: false,
      expandedHeight: 80,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userName,
            style: TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => _showFilterOptions(context),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dateFilterLabel,
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more_rounded,
                  color: AppConstants.textPrimary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppConstants.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Icon(
              Icons.settings_rounded,
              color: AppConstants.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBalanceCard(ExpenseLoaded state) {
    final currencySymbol = context.currencySymbol;
    final isYearly =
        _dateFilterLabel.length == 4 && int.tryParse(_dateFilterLabel) != null;
    final trendData = _getTrendData(
      state.expenses,
      state.currentMonth,
      isYearly,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8F00FF), Color(0xFF6B00FD), Color(0xFF5110E6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F00FF).withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.greenAccent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isYearly
                                  ? 'Yearly Live'
                                  : DateFormat.yMMMM().format(
                                      state.currentMonth,
                                    ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.receipt_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${state.expenses.length} txns',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'TOTAL EXPENSES',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currencySymbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.totalAmount.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (trendData.length >= 2) ...[
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: SparklinePainter(
                          trendData,
                          Colors.white.withOpacity(0.8),
                          [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _getTrendData(
    List<ExpenseModel> expenses,
    DateTime currentMonth,
    bool isYearly,
  ) {
    if (expenses.isEmpty) return [0.0, 0.0];

    if (isYearly) {
      final Map<int, double> monthlySums = {};
      for (int m = 1; m <= 12; m++) {
        monthlySums[m] = 0.0;
      }
      for (final exp in expenses) {
        final m = exp.date.month;
        monthlySums[m] = (monthlySums[m] ?? 0.0) + exp.amount;
      }
      final list = monthlySums.entries.map((e) => e.value).toList();
      if (list.every((v) => v == 0.0)) return [0.0, 0.0];
      return list;
    } else {
      final lastDay = DateTime(
        currentMonth.year,
        currentMonth.month + 1,
        0,
      ).day;
      final Map<int, double> dailySums = {};
      for (int d = 1; d <= lastDay; d++) {
        dailySums[d] = 0.0;
      }
      for (final exp in expenses) {
        final d = exp.date.day;
        if (d <= lastDay) {
          dailySums[d] = (dailySums[d] ?? 0.0) + exp.amount;
        }
      }
      final list = dailySums.entries.map((e) => e.value).toList();
      if (list.every((v) => v == 0.0)) return [0.0, 0.0];
      return list;
    }
  }

  Widget _buildQuickStats(ExpenseLoaded state) {
    final currencySymbol = context.currencySymbol;
    String topCategoryName = 'None';
    double topCategoryValue = 0.0;

    if (state.categoryTotals.isNotEmpty) {
      final sorted = state.categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCategoryName = sorted.first.key;
      topCategoryValue = sorted.first.value;
    }

    final daysInPeriod =
        _dateFilterLabel.length == 4 && int.tryParse(_dateFilterLabel) != null
        ? 365
        : DateTime(
            state.currentMonth.year,
            state.currentMonth.month + 1,
            0,
          ).day;

    final dailyAvg = state.totalAmount / (daysInPeriod > 0 ? daysInPeriod : 30);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'TOP CATEGORY',
              topCategoryName,
              '$currencySymbol${topCategoryValue.toStringAsFixed(0)}',
              const Color(0xFF8B5CF6),
              AppConstants.categoryIcons[topCategoryName] ??
                  Icons.category_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'DAILY AVERAGE',
              'Per day spending',
              '$currencySymbol${dailyAvg.toStringAsFixed(0)}',
              const Color(0xFF10B981),
              Icons.calendar_month_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String subtitle,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetModule(ExpenseLoaded state) {
    final isYearly =
        _dateFilterLabel.length == 4 && int.tryParse(_dateFilterLabel) != null;
    final currencySymbol = context.currencySymbol;

    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, budgetState) {
        // Use the selected date to pick the right per-month or per-year budget
        final refDate = _selectedMonth ?? DateTime.now();
        final budget = budgetState.getBudgetForDate(
          refDate,
          forceYearly: isYearly,
        );
        final totalSpent = state.totalAmount;

        if (budget <= 0.0) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppConstants.isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wallet_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isYearly ? 'Set Yearly Budget' : 'Set Monthly Budget',
                        style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Define a budget limit in settings to track your usage.',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetSettingsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Setup',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final isExceeded = totalSpent > budget;
        final realUsedPct = (totalSpent / budget) * 100;
        final usedPct = realUsedPct.clamp(0.0, 100.0);
        final remainingPct = isExceeded
            ? 0.0
            : (100.0 - realUsedPct).clamp(0.0, 100.0);
        final remainingAmount = isExceeded
            ? 0.0
            : (budget - totalSpent).clamp(0.0, double.infinity);
        final exceededAmount = isExceeded ? (totalSpent - budget) : 0.0;
        final exceededPct = isExceeded
            ? ((exceededAmount / budget) * 100)
            : 0.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppConstants.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isYearly ? 'YEARLY BUDGET STATUS' : 'MONTHLY BUDGET STATUS',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '$currencySymbol${totalSpent.toStringAsFixed(0)} / $currencySymbol${budget.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isExceeded
                          ? const Color(0xFFEF4444)
                          : AppConstants.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: usedPct / 100.0,
                              strokeWidth: 8,
                              backgroundColor: AppConstants.textPrimary
                                  .withOpacity(0.05),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF8B5CF6),
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Text(
                                '${realUsedPct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: AppConstants.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'BUDGET USED',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$currencySymbol${totalSpent.toStringAsFixed(0)} spent',
                        style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: isExceeded ? 1.0 : (remainingPct / 100.0),
                              strokeWidth: 8,
                              backgroundColor: AppConstants.textPrimary
                                  .withOpacity(0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isExceeded
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981),
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Text(
                                isExceeded
                                    ? '+${exceededPct.toStringAsFixed(0)}%'
                                    : '${remainingPct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: isExceeded
                                      ? const Color(0xFFEF4444)
                                      : AppConstants.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isExceeded ? 'EXCEEDED' : 'REMAINING',
                        style: TextStyle(
                          color: isExceeded
                              ? const Color(0xFFEF4444)
                              : AppConstants.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isExceeded
                            ? '$currencySymbol${exceededAmount.toStringAsFixed(0)} over'
                            : '$currencySymbol${remainingAmount.toStringAsFixed(0)} left',
                        style: TextStyle(
                          color: isExceeded
                              ? const Color(0xFFEF4444)
                              : AppConstants.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesCard(ExpenseLoaded state) {
    if (state.categoryTotals.isEmpty) return const SizedBox.shrink();

    final sortedCategories = state.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(5).toList();
    final maxValue = topCategories.first.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppConstants.isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENDING BY CATEGORIES',
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          ...topCategories.map((entry) {
            final percentage = maxValue > 0 ? (entry.value / maxValue) : 0.0;
            final color = AppConstants.categoryColors[entry.key] ?? Colors.grey;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppConstants.categoryIcons[entry.key] ??
                          Icons.category_rounded,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppConstants.textPrimary.withOpacity(
                                  0.05,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percentage,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${context.currencySymbol}${entry.value.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context, ExpenseState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              'Expense Log',
              'Detailed history',
              Icons.receipt_long_rounded,
              const Color(0xFF3F8CFF),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpenseLogScreen(
                    selectedMonth: _selectedMonth,
                    selectedDateRange: _selectedDateRange,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              'Analytics',
              'Spending insights',
              Icons.pie_chart_rounded,
              const Color(0xFFFF565E),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppConstants.isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppConstants.textSecondary,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context, DateTime currentMonth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: MonthYearPicker(
          currentDate: currentMonth,
          onMonthYearSelected: (selectedDate) {
            setState(() {
              _dateFilterLabel = DateFormat.MMM().format(selectedDate);
              _selectedMonth = selectedDate;
              _selectedDateRange = null;
            });
            context.read<ExpenseBloc>().add(LoadExpenses(month: selectedDate));
            Navigator.pop(modalContext);
          },
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: Color(0xFF8B5CF6),
              ),
              title: Text(
                'By Month',
                style: TextStyle(color: AppConstants.textPrimary),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                final state = context.read<ExpenseBloc>().state;
                DateTime initial = DateTime.now();
                if (state is ExpenseLoaded) initial = state.currentMonth;
                _showMonthPicker(context, initial);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: Color(0xFF8B5CF6),
              ),
              title: Text(
                'By Year',
                style: TextStyle(color: AppConstants.textPrimary),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                _showYearPicker(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: Color(0xFF8B5CF6)),
              title: Text(
                'Custom Range',
                style: TextStyle(color: AppConstants.textPrimary),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                _showCustomDateRangePicker(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showYearPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            "Select Year",
            style: TextStyle(color: AppConstants.textPrimary),
          ),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF8B5CF6),
                  onPrimary: Colors.white,
                  surface: AppConstants.cardColor,
                ),
              ),
              child: YearPicker(
                firstDate: DateTime(DateTime.now().year - 10, 1),
                lastDate: DateTime(DateTime.now().year + 10, 1),
                initialDate: DateTime.now(),
                selectedDate: DateTime.now(),
                onChanged: (DateTime dateTime) {
                  Navigator.pop(dialogContext);
                  final start = DateTime(dateTime.year, 1, 1);
                  final end = DateTime(dateTime.year, 12, 31, 23, 59, 59);
                  setState(() {
                    _dateFilterLabel = DateFormat.y().format(dateTime);
                    _selectedMonth = null;
                    _selectedDateRange = DateTimeRange(start: start, end: end);
                  });
                  context.read<ExpenseBloc>().add(
                    LoadExpensesByDateRange(startDate: start, endDate: end),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCustomDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => const DateRangePickerWidget(),
    );

    if (picked != null && mounted) {
      final start = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      final end = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
      setState(() {
        _dateFilterLabel =
            "${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}";
        _selectedMonth = null;
        _selectedDateRange = DateTimeRange(start: start, end: end);
      });
      context.read<ExpenseBloc>().add(
        LoadExpensesByDateRange(startDate: start, endDate: end),
      );
    }
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF8F00FF), Color(0xFF6B00FD)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F00FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AddExpenseScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutCubic;
                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
            ),
          );

          if (result == true && mounted) {
            context.read<ExpenseBloc>().add(RefreshExpenses());
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final List<Color> fillGradientColors;

  SparklinePainter(this.data, this.lineColor, this.fillGradientColors);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paintLine = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double stepX = size.width / (data.length - 1);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y =
          size.height - 5 - ((data[i] - minVal) / range * (size.height - 10));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: fillGradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => true;
}
