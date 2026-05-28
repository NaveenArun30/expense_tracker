enum BudgetMode { monthly, yearly }

enum BudgetAllocation { fixed, individual }

class BudgetState {
  final BudgetMode mode;
  final BudgetAllocation monthlyAllocation;
  final BudgetAllocation yearlyAllocation;

  /// Fixed budget applied to every month (used when monthlyAllocation == fixed)
  final double monthlyFixed;

  /// Fixed budget applied to every year (used when yearlyAllocation == fixed)
  final double yearlyFixed;

  /// Per-month budget overrides (key: 1..12). Only used when monthlyAllocation == individual.
  final Map<int, double> monthlyBudgets;

  /// Per-year budget overrides (key: e.g. 2024). Only used when yearlyAllocation == individual.
  final Map<int, double> yearlyBudgets;

  const BudgetState({
    this.mode = BudgetMode.monthly,
    this.monthlyAllocation = BudgetAllocation.fixed,
    this.yearlyAllocation = BudgetAllocation.fixed,
    this.monthlyFixed = 0.0,
    this.yearlyFixed = 0.0,
    this.monthlyBudgets = const {},
    this.yearlyBudgets = const {},
  });

  // ── Backward-compat getters ───────────────────────────────────────────────
  double get monthlyBudget => monthlyFixed;
  double get yearlyBudget => yearlyFixed;

  // ── Smart lookup ──────────────────────────────────────────────────────────
  /// Returns the effective budget for the given date based on active mode,
  /// allocation type, and per-period overrides.
  ///
  /// Fall-back chain (monthly individual): individual month → fixed monthly
  /// Fall-back chain (yearly individual):  individual year  → fixed yearly
  double getBudgetForDate(DateTime date, {bool forceYearly = false}) {
    final useYearly = forceYearly || mode == BudgetMode.yearly;

    if (useYearly) {
      if (yearlyAllocation == BudgetAllocation.individual) {
        final override = yearlyBudgets[date.year] ?? 0.0;
        return override > 0 ? override : yearlyFixed;
      }
      return yearlyFixed;
    } else {
      if (monthlyAllocation == BudgetAllocation.individual) {
        final override = monthlyBudgets[date.month] ?? 0.0;
        return override > 0 ? override : monthlyFixed;
      }
      return monthlyFixed;
    }
  }

  BudgetState copyWith({
    BudgetMode? mode,
    BudgetAllocation? monthlyAllocation,
    BudgetAllocation? yearlyAllocation,
    double? monthlyFixed,
    double? yearlyFixed,
    Map<int, double>? monthlyBudgets,
    Map<int, double>? yearlyBudgets,
  }) {
    return BudgetState(
      mode: mode ?? this.mode,
      monthlyAllocation: monthlyAllocation ?? this.monthlyAllocation,
      yearlyAllocation: yearlyAllocation ?? this.yearlyAllocation,
      monthlyFixed: monthlyFixed ?? this.monthlyFixed,
      yearlyFixed: yearlyFixed ?? this.yearlyFixed,
      monthlyBudgets: monthlyBudgets ?? this.monthlyBudgets,
      yearlyBudgets: yearlyBudgets ?? this.yearlyBudgets,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetState &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          monthlyAllocation == other.monthlyAllocation &&
          yearlyAllocation == other.yearlyAllocation &&
          monthlyFixed == other.monthlyFixed &&
          yearlyFixed == other.yearlyFixed;

  @override
  int get hashCode =>
      mode.hashCode ^
      monthlyAllocation.hashCode ^
      yearlyAllocation.hashCode ^
      monthlyFixed.hashCode ^
      yearlyFixed.hashCode;
}
