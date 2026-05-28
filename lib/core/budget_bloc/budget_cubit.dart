import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/preferences_service.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  final PreferencesService _prefs;

  BudgetCubit({required PreferencesService preferencesService})
      : _prefs = preferencesService,
        super(const BudgetState());

  // ─────────────────────────────────────────────────────────────────────────
  // Load all saved budget data from SharedPreferences
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadBudgets() async {
    final modeStr = await _prefs.getBudgetActiveMode();
    final monthlyAllocStr = await _prefs.getMonthlyAllocation();
    final yearlyAllocStr = await _prefs.getYearlyAllocation();

    final monthlyFixed = await _prefs.getMonthlyFixed();
    final yearlyFixed = await _prefs.getYearlyFixed();
    final monthlyBudgets = await _prefs.getAllMonthBudgets();
    final yearlyBudgets = await _prefs.getAllYearBudgets();

    emit(BudgetState(
      mode: modeStr == 'yearly' ? BudgetMode.yearly : BudgetMode.monthly,
      monthlyAllocation: monthlyAllocStr == 'individual'
          ? BudgetAllocation.individual
          : BudgetAllocation.fixed,
      yearlyAllocation: yearlyAllocStr == 'individual'
          ? BudgetAllocation.individual
          : BudgetAllocation.fixed,
      monthlyFixed: monthlyFixed,
      yearlyFixed: yearlyFixed,
      monthlyBudgets: monthlyBudgets,
      yearlyBudgets: yearlyBudgets,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mode switchers
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> setMode(BudgetMode mode) async {
    await _prefs.saveBudgetActiveMode(
        mode == BudgetMode.yearly ? 'yearly' : 'monthly');
    emit(state.copyWith(mode: mode));
  }

  Future<void> setMonthlyAllocation(BudgetAllocation alloc) async {
    await _prefs.saveMonthlyAllocation(
        alloc == BudgetAllocation.individual ? 'individual' : 'fixed');
    emit(state.copyWith(monthlyAllocation: alloc));
  }

  Future<void> setYearlyAllocation(BudgetAllocation alloc) async {
    await _prefs.saveYearlyAllocation(
        alloc == BudgetAllocation.individual ? 'individual' : 'fixed');
    emit(state.copyWith(yearlyAllocation: alloc));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fixed budget setters
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> setMonthlyFixed(double amount) async {
    await _prefs.saveMonthlyFixed(amount);
    emit(state.copyWith(monthlyFixed: amount));
  }

  Future<void> setYearlyFixed(double amount) async {
    await _prefs.saveYearlyFixed(amount);
    emit(state.copyWith(yearlyFixed: amount));
  }

  // Backward-compat aliases
  Future<void> setMonthlyBudget(double amount) => setMonthlyFixed(amount);
  Future<void> setYearlyBudget(double amount) => setYearlyFixed(amount);

  // ─────────────────────────────────────────────────────────────────────────
  // Per-month setters
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> setMonthBudget(int month, double amount) async {
    await _prefs.saveMonthBudget(month, amount);
    final updated = Map<int, double>.from(state.monthlyBudgets);
    updated[month] = amount;
    emit(state.copyWith(monthlyBudgets: updated));
  }

  Future<void> saveAllMonthBudgets(Map<int, double> budgets) async {
    await _prefs.saveAllMonthBudgets(budgets);
    emit(state.copyWith(monthlyBudgets: budgets));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Per-year setters
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> setYearBudget(int year, double amount) async {
    await _prefs.saveYearBudget(year, amount);
    final updated = Map<int, double>.from(state.yearlyBudgets);
    updated[year] = amount;
    emit(state.copyWith(yearlyBudgets: updated));
  }

  Future<void> saveAllYearBudgets(Map<int, double> budgets) async {
    await _prefs.saveAllYearBudgets(budgets);
    emit(state.copyWith(yearlyBudgets: budgets));
  }
}
