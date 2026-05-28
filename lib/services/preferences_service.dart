import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // ── Existing keys ────────────────────────────────────────────────────────
  static const String _kGeminiApiKey = 'gemini_api_key';
  static const String _kCurrencyCode = 'currency_code';

  Future<void> saveGeminiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGeminiApiKey, apiKey);
  }

  Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kGeminiApiKey);
  }

  Future<void> clearGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGeminiApiKey);
  }

  Future<void> saveCurrencyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyCode, code);
  }

  Future<String?> getCurrencyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrencyCode);
  }

  // ── Budget mode keys ──────────────────────────────────────────────────────
  // budget_active_mode: "monthly" | "yearly"
  static const String _kBudgetActiveMode = 'budget_active_mode';
  // monthly_allocation: "fixed" | "individual"
  static const String _kMonthlyAllocation = 'monthly_allocation';
  // yearly_allocation:  "fixed" | "individual"
  static const String _kYearlyAllocation = 'yearly_allocation';

  // ── Fixed values ──────────────────────────────────────────────────────────
  static const String _kMonthlyFixed = 'monthly_budget_fixed';
  static const String _kYearlyFixed = 'yearly_budget_fixed';

  // ── Per-month values (keys: monthly_budget_01 … monthly_budget_12) ────────
  static String _monthKey(int month) =>
      'monthly_budget_${month.toString().padLeft(2, '0')}';

  // ── Per-year values stored as JSON map { "2024": 120000.0, … } ───────────
  static const String _kYearlyMap = 'yearly_budget_map';

  // ─────────────────────────────────────────────────────────────────────────
  // Active mode
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> saveBudgetActiveMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBudgetActiveMode, mode);
  }

  Future<String> getBudgetActiveMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBudgetActiveMode) ?? 'monthly';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Monthly allocation mode
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> saveMonthlyAllocation(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMonthlyAllocation, mode);
  }

  Future<String> getMonthlyAllocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kMonthlyAllocation) ?? 'fixed';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Yearly allocation mode
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> saveYearlyAllocation(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kYearlyAllocation, mode);
  }

  Future<String> getYearlyAllocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kYearlyAllocation) ?? 'fixed';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fixed monthly budget
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> saveMonthlyFixed(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMonthlyFixed, amount);
  }

  Future<double> getMonthlyFixed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kMonthlyFixed) ?? 0.0;
  }

  // Keep backward-compat aliases
  Future<void> saveMonthlyBudget(double amount) => saveMonthlyFixed(amount);
  Future<double> getMonthlyBudget() => getMonthlyFixed();

  // ─────────────────────────────────────────────────────────────────────────
  // Fixed yearly budget
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> saveYearlyFixed(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kYearlyFixed, amount);
  }

  Future<double> getYearlyFixed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kYearlyFixed) ?? 0.0;
  }

  // Keep backward-compat aliases
  Future<void> saveYearlyBudget(double amount) => saveYearlyFixed(amount);
  Future<double> getYearlyBudget() => getYearlyFixed();

  // ─────────────────────────────────────────────────────────────────────────
  // Per-month budgets (month: 1..12)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> saveMonthBudget(int month, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_monthKey(month), amount);
  }

  Future<double> getMonthBudget(int month) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_monthKey(month)) ?? 0.0;
  }

  Future<Map<int, double>> getAllMonthBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <int, double>{};
    for (int m = 1; m <= 12; m++) {
      map[m] = prefs.getDouble(_monthKey(m)) ?? 0.0;
    }
    return map;
  }

  Future<void> saveAllMonthBudgets(Map<int, double> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in budgets.entries) {
      await prefs.setDouble(_monthKey(entry.key), entry.value);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Per-year budgets (key: year integer)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> saveYearBudget(int year, double amount) async {
    final map = await _loadYearlyMap();
    map[year.toString()] = amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kYearlyMap, jsonEncode(map));
  }

  Future<double> getYearBudget(int year) async {
    final map = await _loadYearlyMap();
    final val = map[year.toString()];
    return (val is num) ? val.toDouble() : 0.0;
  }

  Future<Map<int, double>> getAllYearBudgets() async {
    final raw = await _loadYearlyMap();
    return raw.map((k, v) => MapEntry(int.tryParse(k) ?? 0, (v as num).toDouble()));
  }

  Future<void> saveAllYearBudgets(Map<int, double> budgets) async {
    final map = budgets.map((k, v) => MapEntry(k.toString(), v));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kYearlyMap, jsonEncode(map));
  }

  Future<Map<String, dynamic>> _loadYearlyMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kYearlyMap);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }
}
