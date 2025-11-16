import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../constants/app_constants.dart';
import '../../../model/expense_model.dart';

import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadExpensesForSelectedPeriod(BuildContext context) {
    final startDate = DateTime(_selectedYear, _selectedMonth, 1);
    final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);

    context.read<ExpenseBloc>().add(
      LoadExpensesByDateRange(startDate: startDate, endDate: endDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpenseBloc()..add(LoadExpenses()),
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Analytics',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppConstants.textOnPrimary,
            ),
          ),
          backgroundColor: AppConstants.primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppConstants.textOnPrimary),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppConstants.primaryGradient,
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppConstants.textOnPrimary,
            labelColor: AppConstants.textOnPrimary,
            unselectedLabelColor: AppConstants.textOnPrimary.withOpacity(0.7),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Categories'),
              Tab(text: 'Trends'),
            ],
          ),
        ),
        body: BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, state),
                _buildCategoriesTab(context, state),
                _buildTrendsTab(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, ExpenseState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(context),
          const SizedBox(height: 20),
          _buildOverviewCards(state),
          const SizedBox(height: 20),
          _buildMonthlyChart(state),
          const SizedBox(height: 20),
          _buildSpendingInsights(state),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(BuildContext context, ExpenseState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(context),
          const SizedBox(height: 20),
          if (state is ExpenseLoaded) ...[
            _buildCategoryPieChart(state),
            const SizedBox(height: 20),
            _buildCategoryBreakdown(state),
          ] else
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(BuildContext context, ExpenseState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(context),
          const SizedBox(height: 20),
          _buildTrendChart(state),
          const SizedBox(height: 20),
          _buildWeeklyAnalysis(state),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  value: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppConstants.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(months[index]),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value!;
                    });
                    _loadExpensesForSelectedPeriod(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppConstants.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: years.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                    });
                    _loadExpensesForSelectedPeriod(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(ExpenseState state) {
    if (state is ExpenseLoaded) {
      final currentMonthTotal = state.totalAmount;
      final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
      final avgPerDay = state.expenses.isNotEmpty
          ? currentMonthTotal / daysInMonth
          : 0.0;

      return Row(
        children: [
          Expanded(
            child: _buildOverviewCard(
              'Monthly Total',
              '${currentMonthTotal.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildOverviewCard(
              'Daily Average',
              '${avgPerDay.toStringAsFixed(2)}',
              Icons.today,
              AppConstants.successColor,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(ExpenseState state) {
    if (state is ExpenseLoaded) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Spending Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: state.expenses.isEmpty
                  ? Center(
                      child: Text(
                        'No expenses for this period',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : LineChart(_buildLineChartData(state.expenses)),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  LineChartData _buildLineChartData(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return LineChartData(
        lineBarsData: [],
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
      );
    }

    // Group expenses by day of month
    Map<int, double> dailyTotals = {};
    for (var expense in expenses) {
      final day = expense.date.day;
      dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
    }

    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    List<FlSpot> spots = [];
    for (int day = 1; day <= daysInMonth; day++) {
      spots.add(FlSpot(day.toDouble(), dailyTotals[day] ?? 0));
    }

    final maxY = dailyTotals.values.isEmpty
        ? 100.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey[200], strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 1,
      maxX: daysInMonth.toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(colors: AppConstants.primaryGradient),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: AppConstants.primaryGradient
                  .map((color) => color.withOpacity(0.2))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(ExpenseLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: state.categoryTotals.isEmpty
                ? Center(
                    child: Text(
                      'No expenses for this period',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : PieChart(_buildPieChartData(state.categoryTotals)),
          ),
        ],
      ),
    );
  }

  PieChartData _buildPieChartData(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) {
      return PieChartData(sections: []);
    }

    final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);

    return PieChartData(
      sections: categoryTotals.entries.map((entry) {
        final percentage = (entry.value / total * 100);
        final color = AppConstants.categoryColors[entry.key] ?? Colors.grey;

        return PieChartSectionData(
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          color: color,
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList(),
      sectionsSpace: 2,
      centerSpaceRadius: 0,
    );
  }

  Widget _buildCategoryBreakdown(ExpenseLoaded state) {
    if (state.categoryTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No category data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final sortedCategories = state.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          ...sortedCategories.map((entry) {
            final color = AppConstants.categoryColors[entry.key] ?? Colors.grey;
            final icon =
                AppConstants.categoryIcons[entry.key] ?? Icons.category;
            final percentage = (entry.value / state.totalAmount * 100);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}% of total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTrendChart(ExpenseState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Spending Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: state is ExpenseLoaded && state.expenses.isEmpty
                ? Center(
                    child: Text(
                      'No expenses for this period',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : BarChart(_buildBarChartData(state)),
          ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartData(ExpenseState state) {
    if (state is! ExpenseLoaded || state.expenses.isEmpty) {
      return BarChartData(
        barGroups: [],
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
      );
    }

    // Group expenses by week
    Map<int, double> weeklyTotals = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

    for (var expense in state.expenses) {
      final weekday = expense.date.weekday - 1; // 0 = Monday, 6 = Sunday
      weeklyTotals[weekday] = (weeklyTotals[weekday] ?? 0) + expense.amount;
    }

    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxValue = weeklyTotals.values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue > 0 ? maxValue * 1.2 : 100.0;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${weekDays[group.x.toInt()]}${rod.toY.toStringAsFixed(2)}',
              const TextStyle(color: Colors.white),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                weekDays[value.toInt()],
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: weeklyTotals.entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              gradient: LinearGradient(
                colors: AppConstants.primaryGradient,
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyAnalysis(ExpenseState state) {
    if (state is! ExpenseLoaded || state.expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No weekly data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Calculate weekly statistics
    Map<int, double> weeklyTotals = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    Map<int, int> weeklyCount = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

    for (var expense in state.expenses) {
      final weekday = expense.date.weekday - 1;
      weeklyTotals[weekday] = (weeklyTotals[weekday] ?? 0) + expense.amount;
      weeklyCount[weekday] = (weeklyCount[weekday] ?? 0) + 1;
    }

    final weekDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    // Find max/min with safety checks
    final nonZeroTotals = weeklyTotals.entries
        .where((e) => e.value > 0)
        .toList();

    if (nonZeroTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No weekly data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final maxSpendingDay = nonZeroTotals.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final minSpendingDay = nonZeroTotals.reduce(
      (a, b) => a.value < b.value ? a : b,
    );
    final maxCountDay = weeklyCount.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            'Highest Spending Day',
            weekDays[maxSpendingDay.key],
            '${maxSpendingDay.value.toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Lowest Spending Day',
            weekDays[minSpendingDay.key],
            '${minSpendingDay.value.toStringAsFixed(2)}',
            Icons.trending_down,
            AppConstants.successColor,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Most Active Day',
            weekDays[maxCountDay.key],
            '${maxCountDay.value} transactions',
            Icons.receipt_long,
            AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String subtitle,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
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
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingInsights(ExpenseState state) {
    if (state is! ExpenseLoaded || state.expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No spending data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final avgTransaction = state.expenses.isNotEmpty
        ? state.totalAmount / state.expenses.length
        : 0.0;

    final topCategory = state.categoryTotals.entries.isNotEmpty
        ? state.categoryTotals.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          )
        : null;

    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final currentDay = DateTime.now().day;
    final remainingDays = daysInMonth - currentDay;
    final projectedBudget = remainingDays > 0
        ? (state.totalAmount / currentDay) * remainingDays
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          if (topCategory != null) ...[
            _buildInsightCard(
              'Top Category',
              topCategory.key,
              '${topCategory.value.toStringAsFixed(2)}',
              '${((topCategory.value / state.totalAmount) * 100).toStringAsFixed(1)}% of total',
              AppConstants.categoryColors[topCategory.key] ?? Colors.grey,
              AppConstants.categoryIcons[topCategory.key] ?? Icons.category,
            ),
            const SizedBox(height: 12),
          ],
          _buildInsightCard(
            'Average Transaction',
            'Per expense',
            '${avgTransaction.toStringAsFixed(2)}',
            'Based on ${state.expenses.length} transactions',
            AppConstants.primaryColor,
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'Projected Spending',
            'Rest of month',
            '${projectedBudget.toStringAsFixed(2)}',
            'Based on current spending pattern',
            AppConstants.successColor,
            Icons.savings,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String subtitle,
    String value,
    String description,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
