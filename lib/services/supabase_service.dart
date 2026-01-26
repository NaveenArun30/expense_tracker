import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/expense_model.dart';
import '../model/income_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Add expense
  static Future<ExpenseModel?> addExpense(ExpenseModel expense) async {
    try {
      final response = await _client
          .from('expenses')
          .insert(expense.toJson())
          .select()
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      print('Error adding expense: $e');
      return null;
    }
  }

  // Get all expenses for a user (no date filtering)
  static Future<List<ExpenseModel>> getAllExpenses({
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all expenses: $e');
      return [];
    }
  }

  // Get expenses for current month
  static Future<List<ExpenseModel>> getMonthlyExpenses({
    required String userId,
    DateTime? month,
  }) async {
    try {
      final targetMonth = month ?? DateTime.now();
      final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
      final endOfMonth = DateTime(
        targetMonth.year,
        targetMonth.month + 1,
        0,
        23,
        59,
        59,
      );

      final response = await _client
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .gte('date', startOfMonth.toIso8601String())
          .lte('date', endOfMonth.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching expenses: $e');
      return [];
    }
  }

  // Get expenses by date range
  static Future<List<ExpenseModel>> getExpensesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching expenses by date range: $e');
      return [];
    }
  }

  // Get yearly expenses
  static Future<List<ExpenseModel>> getYearlyExpenses({
    required String userId,
    required int year,
  }) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

      final response = await _client
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .gte('date', startOfYear.toIso8601String())
          .lte('date', endOfYear.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching yearly expenses: $e');
      return [];
    }
  }

  // Delete expense
  static Future<bool> deleteExpense(String expenseId) async {
    try {
      await _client.from('expenses').delete().eq('id', expenseId);
      return true;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  // Get category-wise expenses
  static Future<Map<String, double>> getCategoryWiseExpenses({
    required String userId,
    DateTime? month,
  }) async {
    try {
      final expenses = await getMonthlyExpenses(userId: userId, month: month);
      final categoryMap = <String, double>{};

      for (var expense in expenses) {
        categoryMap[expense.category] =
            (categoryMap[expense.category] ?? 0) + expense.amount;
      }

      return categoryMap;
    } catch (e) {
      print('Error fetching category expenses: $e');
      return {};
    }
  }

  // Get category-wise expenses for date range
  static Future<Map<String, double>> getCategoryWiseExpensesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final expenses = await getExpensesByDateRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      final categoryMap = <String, double>{};

      for (var expense in expenses) {
        categoryMap[expense.category] =
            (categoryMap[expense.category] ?? 0) + expense.amount;
      }

      return categoryMap;
    } catch (e) {
      print('Error fetching category expenses by date range: $e');
      return {};
    }
  }

  // Get category-wise expenses for all expenses
  static Future<Map<String, double>> getAllCategoryWiseExpenses({
    required String userId,
  }) async {
    try {
      final expenses = await getAllExpenses(userId: userId);
      final categoryMap = <String, double>{};

      for (var expense in expenses) {
        categoryMap[expense.category] =
            (categoryMap[expense.category] ?? 0) + expense.amount;
      }

      return categoryMap;
    } catch (e) {
      print('Error fetching all category expenses: $e');
      return {};
    }
  }

  static Future<AccountModel?> addAccount(AccountModel account) async {
    try {
      final response = await _client
          .from('accounts')
          .insert(account.toJson())
          .select()
          .single();

      return AccountModel.fromJson(response);
    } catch (e) {
      print('Error adding account: $e');
      return null;
    }
  }

  // Get all accounts for a user
  static Future<List<AccountModel>> getAccounts({
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('accounts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AccountModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching accounts: $e');
      return [];
    }
  }

  // Update account balance
  static Future<bool> updateAccountBalance({
    required String accountId,
    required double newBalance,
  }) async {
    try {
      await _client
          .from('accounts')
          .update({'balance': newBalance})
          .eq('id', accountId);
      return true;
    } catch (e) {
      print('Error updating account balance: $e');
      return false;
    }
  }

  // Delete account
  static Future<bool> deleteAccount(String accountId) async {
    try {
      await _client.from('accounts').delete().eq('id', accountId);
      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  // Get total balance across all accounts
  static Future<double> getTotalBalance({required String userId}) async {
    try {
      final accounts = await getAccounts(userId: userId);
      return accounts.fold<double>(
        0.0,
        (sum, account) => sum + account.balance,
      );
    } catch (e) {
      print('Error calculating total balance: $e');
      return 0.0;
    }
  }

  // ============ INCOME OPERATIONS ============

  // Add income
  static Future<IncomeModel?> addIncome(IncomeModel income) async {
    try {
      final response = await _client
          .from('income')
          .insert(income.toJson())
          .select()
          .single();

      return IncomeModel.fromJson(response);
    } catch (e) {
      print('Error adding income: $e');
      return null;
    }
  }

  // Get all income for a user
  static Future<List<IncomeModel>> getAllIncome({
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('income')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => IncomeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all income: $e');
      return [];
    }
  }

  // Get monthly income
  static Future<List<IncomeModel>> getMonthlyIncome({
    required String userId,
    DateTime? month,
  }) async {
    try {
      final targetMonth = month ?? DateTime.now();
      final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
      final endOfMonth = DateTime(
        targetMonth.year,
        targetMonth.month + 1,
        0,
        23,
        59,
        59,
      );

      final response = await _client
          .from('income')
          .select()
          .eq('user_id', userId)
          .gte('date', startOfMonth.toIso8601String())
          .lte('date', endOfMonth.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => IncomeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching monthly income: $e');
      return [];
    }
  }

  // Get income by date range
  static Future<List<IncomeModel>> getIncomeByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client
          .from('income')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => IncomeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching income by date range: $e');
      return [];
    }
  }

  // Delete income
  static Future<bool> deleteIncome(String incomeId) async {
    try {
      await _client.from('income').delete().eq('id', incomeId);
      return true;
    } catch (e) {
      print('Error deleting income: $e');
      return false;
    }
  }

  // Get source-wise income
  static Future<Map<String, double>> getSourceWiseIncome({
    required String userId,
    DateTime? month,
  }) async {
    try {
      final income = await getMonthlyIncome(userId: userId, month: month);
      final sourceMap = <String, double>{};

      for (var item in income) {
        sourceMap[item.source] = (sourceMap[item.source] ?? 0) + item.amount;
      }

      return sourceMap;
    } catch (e) {
      print('Error fetching source-wise income: $e');
      return {};
    }
  }
}
