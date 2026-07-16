import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_constants.dart';
import '../../core/budget_bloc/budget_cubit.dart';
import '../../core/budget_bloc/budget_state.dart';
import '../../core/currency_bloc/currency_cubit.dart';
import '../../core/currency_bloc/currency_state.dart';
import 'package:go_router/go_router.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // ── Local draft state (we apply everything on Save) ──────────────────────
  late BudgetMode _activeMode;
  late BudgetAllocation _monthlyAlloc;
  late BudgetAllocation _yearlyAlloc;
  late double _monthlyFixed;
  late double _yearlyFixed;
  late Map<int, double> _monthlyBudgets;
  late Map<int, double> _yearlyBudgets;

  bool _initialized = false;
  String _currencySymbol = '₹';

  // ── Year range ────────────────────────────────────────────────────────────
  final int _currentYear = DateTime.now().year;
  late List<int> _years;

  // ── Month names ───────────────────────────────────────────────────────────
  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _years = List.generate(14, (i) => _currentYear - 3 + i); // 3 past + 10 future
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final s = context.read<BudgetCubit>().state;
      _activeMode = s.mode;
      _monthlyAlloc = s.monthlyAllocation;
      _yearlyAlloc = s.yearlyAllocation;
      _monthlyFixed = s.monthlyFixed;
      _yearlyFixed = s.yearlyFixed;
      _monthlyBudgets = Map<int, double>.from(s.monthlyBudgets);
      _yearlyBudgets = Map<int, double>.from(s.yearlyBudgets);
      // Ensure all months are initialised
      for (int m = 1; m <= 12; m++) {
        _monthlyBudgets.putIfAbsent(m, () => 0.0);
      }
      for (final y in _years) {
        _yearlyBudgets.putIfAbsent(y, () => 0.0);
      }
      // Set initial tab
      _tabController.index = _activeMode == BudgetMode.yearly ? 1 : 0;
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {
            _activeMode =
                _tabController.index == 1 ? BudgetMode.yearly : BudgetMode.monthly;
          });
        }
      });

      _currencySymbol =
          context.read<CurrencyCubit>().state.selectedCurrency.symbol;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final cubit = context.read<BudgetCubit>();
    await cubit.setMode(_activeMode);
    await cubit.setMonthlyAllocation(_monthlyAlloc);
    await cubit.setYearlyAllocation(_yearlyAlloc);
    await cubit.setMonthlyFixed(_monthlyFixed);
    await cubit.setYearlyFixed(_yearlyFixed);
    await cubit.saveAllMonthBudgets(_monthlyBudgets);
    await cubit.saveAllYearBudgets(_yearlyBudgets);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Budget settings saved!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF8B5CF6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDark;
    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (context, currencyState) {
        _currencySymbol = currencyState.selectedCurrency.symbol;
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildTabBar(isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMonthlyTab(isDark),
                    _buildYearlyTab(isDark),
                  ],
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.primaryColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        'Budget Settings',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppConstants.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab bar — MONTHLY | YEARLY pill
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppConstants.textSecondary,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'MONTHLY'),
          Tab(text: 'YEARLY'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MONTHLY TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMonthlyTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        _buildAllocationToggle(
          label: 'Budget Type',
          subtitle: 'Apply one fixed amount to every month, or set each month separately.',
          value: _monthlyAlloc,
          fixedLabel: 'Fixed for all months',
          individualLabel: 'Set per month',
          onChanged: (v) => setState(() => _monthlyAlloc = v),
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        if (_monthlyAlloc == BudgetAllocation.fixed) ...[
          _buildSectionLabel('Monthly Fixed Budget'),
          const SizedBox(height: 12),
          _buildAmountStepper(
            value: _monthlyFixed,
            onChanged: (v) => setState(() => _monthlyFixed = v),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildPresetChips(
            onSelect: (v) => setState(() => _monthlyFixed = v),
            isDark: isDark,
          ),
        ] else ...[
          _buildSectionLabel('Budget per Month'),
          const SizedBox(height: 12),
          ...List.generate(12, (i) {
            final month = i + 1;
            return _buildMonthRow(month, isDark);
          }),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // YEARLY TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildYearlyTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        _buildAllocationToggle(
          label: 'Budget Type',
          subtitle: 'Apply one fixed amount to every year, or set each year separately.',
          value: _yearlyAlloc,
          fixedLabel: 'Fixed for all years',
          individualLabel: 'Set per year',
          onChanged: (v) => setState(() => _yearlyAlloc = v),
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        if (_yearlyAlloc == BudgetAllocation.fixed) ...[
          _buildSectionLabel('Yearly Fixed Budget'),
          const SizedBox(height: 12),
          _buildAmountStepper(
            value: _yearlyFixed,
            onChanged: (v) => setState(() => _yearlyFixed = v),
            isDark: isDark,
            largeSteps: true,
          ),
          const SizedBox(height: 16),
          _buildPresetChips(
            onSelect: (v) => setState(() => _yearlyFixed = v),
            isDark: isDark,
            yearly: true,
          ),
        ] else ...[
          _buildSectionLabel('Budget per Year'),
          const SizedBox(height: 12),
          ...(_years.map((year) => _buildYearRow(year, isDark))),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Allocation toggle
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAllocationToggle({
    required String label,
    required String subtitle,
    required BudgetAllocation value,
    required String fixedLabel,
    required String individualLabel,
    required ValueChanged<BudgetAllocation> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: AppConstants.textSecondary, fontSize: 11)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _toggleChip(
                label: fixedLabel,
                selected: value == BudgetAllocation.fixed,
                onTap: () => onChanged(BudgetAllocation.fixed),
                isDark: isDark,
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _toggleChip(
                label: individualLabel,
                selected: value == BudgetAllocation.individual,
                onTap: () => onChanged(BudgetAllocation.individual),
                isDark: isDark,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)])
              : null,
          color: selected
              ? null
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:
                        const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppConstants.textSecondary,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Per-month row
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMonthRow(int month, bool isDark) {
    final isCurrentMonth = month == DateTime.now().month;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(isDark,
          highlight: isCurrentMonth),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCurrentMonth
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _monthNames[month - 1].substring(0, 3).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isCurrentMonth
                      ? const Color(0xFF8B5CF6)
                      : AppConstants.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _monthNames[month - 1],
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontWeight: isCurrentMonth ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          _buildCompactStepper(
            value: _monthlyBudgets[month] ?? 0.0,
            onChanged: (v) => setState(() => _monthlyBudgets[month] = v),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Per-year row
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildYearRow(int year, bool isDark) {
    final isCurrentYear = year == _currentYear;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(isDark, highlight: isCurrentYear),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrentYear
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              year.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isCurrentYear
                    ? const Color(0xFF8B5CF6)
                    : AppConstants.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCurrentYear ? 'Current Year' : (year < _currentYear ? 'Past Year' : 'Future Year'),
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          _buildCompactStepper(
            value: _yearlyBudgets[year] ?? 0.0,
            onChanged: (v) => setState(() => _yearlyBudgets[year] = v),
            isDark: isDark,
            largeSteps: true,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Large amount stepper (for fixed budget)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAmountStepper({
    required double value,
    required ValueChanged<double> onChanged,
    required bool isDark,
    bool largeSteps = false,
  }) {
    final step = largeSteps ? 5000.0 : 1000.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          // Value display
          Text(
            '$_currencySymbol ${_formatAmount(value)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8B5CF6),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text('Tap the value to type directly',
              style: TextStyle(
                  color: AppConstants.textTertiary, fontSize: 11)),
          const SizedBox(height: 20),
          Row(
            children: [
              // Decrease
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: () => onChanged((value - step).clamp(0, double.infinity)),
                onLongPress: () => _startRepeating(() =>
                    onChanged((value - step).clamp(0, double.infinity))),
                onLongPressEnd: _stopRepeating,
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: 12),
              // Text field
              Expanded(
                child: _AmountTextField(
                  value: value,
                  currencySymbol: _currencySymbol,
                  onChanged: onChanged,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              // Increase
              _StepButton(
                icon: Icons.add_rounded,
                onTap: () => onChanged(value + step),
                onLongPress: () =>
                    _startRepeating(() => onChanged(value + step)),
                onLongPressEnd: _stopRepeating,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Compact stepper (for per-month/year rows)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCompactStepper({
    required double value,
    required ValueChanged<double> onChanged,
    required bool isDark,
    bool largeSteps = false,
  }) {
    final step = largeSteps ? 5000.0 : 500.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniStepButton(
          icon: Icons.remove_rounded,
          color: const Color(0xFFEF4444),
          onTap: () => onChanged((value - step).clamp(0, double.infinity)),
          onLongPress: () => _startRepeating(
              () => onChanged((value - step).clamp(0, double.infinity))),
          onLongPressEnd: _stopRepeating,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final result = await _showAmountInputDialog(value);
            if (result != null) onChanged(result);
          },
          child: Container(
            constraints: const BoxConstraints(minWidth: 80),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value > 0
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              value > 0 ? '$_currencySymbol${_formatAmount(value)}' : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: value > 0
                    ? const Color(0xFF8B5CF6)
                    : AppConstants.textTertiary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _miniStepButton(
          icon: Icons.add_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => onChanged(value + step),
          onLongPress: () =>
              _startRepeating(() => onChanged(value + step)),
          onLongPressEnd: _stopRepeating,
        ),
      ],
    );
  }

  Widget _miniStepButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressEnd,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quick preset chips
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPresetChips({
    required ValueChanged<double> onSelect,
    required bool isDark,
    bool yearly = false,
  }) {
    // Presets in the selected currency's denomination
    final presets = yearly
        ? [50000.0, 100000.0, 200000.0, 500000.0]
        : [5000.0, 10000.0, 25000.0, 50000.0];
    final labels = yearly
        ? ['${_currencySymbol}50K', '${_currencySymbol}1L', '${_currencySymbol}2L', '${_currencySymbol}5L']
        : ['${_currencySymbol}5K', '${_currencySymbol}10K', '${_currencySymbol}25K', '${_currencySymbol}50K'];

    return Wrap(
      spacing: 10,
      children: List.generate(presets.length, (i) {
        return GestureDetector(
          onTap: () => onSelect(presets[i]),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(20),
              color: isDark
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.08)
                  : const Color(0xFF8B5CF6).withValues(alpha: 0.06),
            ),
            child: Text(
              labels[i],
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save button
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        border: Border(
          top: BorderSide(
            color: AppConstants.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: GestureDetector(
        onTap: _save,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Budget Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppConstants.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark, {bool highlight = false}) {
    return BoxDecoration(
      color: AppConstants.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: highlight
            ? const Color(0xFF8B5CF6).withValues(alpha: 0.35)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06)),
        width: highlight ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  String _formatAmount(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  // Long-press repeat
  Timer? _repeatTimer;

  void _startRepeating(VoidCallback action) {
    _repeatTimer?.cancel();
    _repeatTimer =
        Timer.periodic(const Duration(milliseconds: 120), (_) => action());
  }

  void _stopRepeating() => _repeatTimer?.cancel();

  // Dialog to type an amount manually (for compact steppers)
  Future<double?> _showAmountInputDialog(double current) async {
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Enter Amount',
            style: TextStyle(
                color: AppConstants.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
          ],
          style: TextStyle(color: AppConstants.textPrimary),
          decoration: InputDecoration(
            prefixText: '$_currencySymbol ',
            prefixStyle: const TextStyle(
                color: Color(0xFF8B5CF6), fontWeight: FontWeight.w700),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: AppConstants.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              Navigator.pop(ctx, v);
            },
            child:
                const Text('Set', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Big stepper +/- button with long-press support
class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onLongPressEnd;

  const _StepButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.onLongPress,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}

/// Inline text field for the large amount stepper
class _AmountTextField extends StatefulWidget {
  final double value;
  final String currencySymbol;
  final ValueChanged<double> onChanged;
  final bool isDark;

  const _AmountTextField({
    required this.value,
    required this.currencySymbol,
    required this.onChanged,
    required this.isDark,
  });

  @override
  State<_AmountTextField> createState() => _AmountTextFieldState();
}

class _AmountTextFieldState extends State<_AmountTextField> {
  late TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.value > 0 ? widget.value.toStringAsFixed(0) : '');
  }

  @override
  void didUpdateWidget(_AmountTextField old) {
    super.didUpdateWidget(old);
    if (!_editing && old.value != widget.value) {
      _ctrl.text =
          widget.value > 0 ? widget.value.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
      ],
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppConstants.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        prefixText: '${widget.currencySymbol} ',
        prefixStyle: TextStyle(
            color: AppConstants.textSecondary, fontWeight: FontWeight.w500),
        hintText: '0',
        hintStyle:
            TextStyle(color: AppConstants.textHint),
        filled: true,
        fillColor: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFF8B5CF6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
      ),
      onTap: () => setState(() => _editing = true),
      onChanged: (v) {
        final d = double.tryParse(v) ?? 0.0;
        widget.onChanged(d);
      },
      onEditingComplete: () {
        setState(() => _editing = false);
        FocusScope.of(context).unfocus();
      },
    );
  }
}
