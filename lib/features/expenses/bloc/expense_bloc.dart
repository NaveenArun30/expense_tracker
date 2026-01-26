import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  String get userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  ExpenseBloc() : super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<LoadExpensesByDateRange>(_onLoadExpensesByDateRange);
    on<LoadYearlyExpenses>(_onLoadYearlyExpenses);
    on<AddExpense>(_onAddExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<RefreshExpenses>(_onRefreshExpenses);
    on<LoadComparisonData>(_onLoadComparisonData);
    on<LoadAllExpenses>(_onLoadAllExpenses);
  }

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        emit(ExpenseError('User not authenticated'));
        return;
      }

      final month = event.month ?? DateTime.now();
      final expenses = await SupabaseService.getMonthlyExpenses(
        userId: currentUserId,
        month: month,
      );

      // Load accounts as well
      final accounts = await SupabaseService.getAccounts(userId: currentUserId);

      final categoryTotals = await SupabaseService.getCategoryWiseExpenses(
        userId: currentUserId,
        month: month,
      );

      final totalAmount = expenses.fold(
        0.0,
        (sum, expense) => sum + expense.amount,
      );

      emit(
        ExpenseLoaded(
          expenses: expenses,
          accounts: accounts,
          totalAmount: totalAmount,
          categoryTotals: categoryTotals,
          currentMonth: month,
        ),
      );
    } catch (e) {
      emit(ExpenseError('Failed to load expenses: $e'));
    }
  }

  Future<void> _onLoadAllExpenses(
    LoadAllExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        emit(ExpenseError('User not authenticated'));
        return;
      }

      final expenses = await SupabaseService.getAllExpenses(
        userId: currentUserId,
      );

      final accounts = await SupabaseService.getAccounts(userId: currentUserId);

      final categoryTotals = <String, double>{};
      for (var expense in expenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      final totalAmount = expenses.fold(
        0.0,
        (sum, expense) => sum + expense.amount,
      );

      emit(
        ExpenseLoaded(
          expenses: expenses,
          accounts: accounts,
          totalAmount: totalAmount,
          categoryTotals: categoryTotals,
          currentMonth: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(ExpenseError('Failed to load all expenses: $e'));
    }
  }

  Future<void> _onLoadExpensesByDateRange(
    LoadExpensesByDateRange event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        emit(ExpenseError('User not authenticated'));
        return;
      }

      final expenses = await SupabaseService.getExpensesByDateRange(
        userId: currentUserId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      final accounts = await SupabaseService.getAccounts(userId: currentUserId);

      final categoryTotals = <String, double>{};
      for (var expense in expenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      final totalAmount = expenses.fold(
        0.0,
        (sum, expense) => sum + expense.amount,
      );

      emit(
        ExpenseLoaded(
          expenses: expenses,
          accounts: accounts,
          totalAmount: totalAmount,
          categoryTotals: categoryTotals,
          currentMonth: event.startDate,
        ),
      );
    } catch (e) {
      emit(ExpenseError('Failed to load expenses by date range: $e'));
    }
  }

  Future<void> _onLoadYearlyExpenses(
    LoadYearlyExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        emit(ExpenseError('User not authenticated'));
        return;
      }

      final expenses = await SupabaseService.getYearlyExpenses(
        userId: currentUserId,
        year: event.year,
      );

      final accounts = await SupabaseService.getAccounts(userId: currentUserId);

      final monthlyTotals = <int, double>{};
      final categoryTotals = <String, double>{};

      for (var expense in expenses) {
        final month = expense.date.month;
        monthlyTotals[month] = (monthlyTotals[month] ?? 0) + expense.amount;
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      final totalAmount = expenses.fold(
        0.0,
        (sum, expense) => sum + expense.amount,
      );

      emit(
        YearlyExpenseLoaded(
          expenses: expenses,
          accounts: accounts,
          monthlyTotals: monthlyTotals,
          categoryTotals: categoryTotals,
          year: event.year,
          totalAmount: totalAmount,
        ),
      );
    } catch (e) {
      emit(ExpenseError('Failed to load yearly expenses: $e'));
    }
  }

  Future<void> _onLoadComparisonData(
    LoadComparisonData event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        emit(ExpenseError('User not authenticated'));
        return;
      }

      final now = DateTime.now();
      DateTime currentStart, currentEnd, previousStart, previousEnd;

      if (event.comparisonType == 'year') {
        currentStart = DateTime(now.year, 1, 1);
        currentEnd = DateTime(now.year, 12, 31, 23, 59, 59);
        previousStart = DateTime(now.year - 1, 1, 1);
        previousEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
      } else {
        currentStart = DateTime(now.year, now.month, 1);
        currentEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        previousStart = DateTime(now.year, now.month - 1, 1);
        previousEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
      }

      final currentExpenses = await SupabaseService.getExpensesByDateRange(
        userId: currentUserId,
        startDate: currentStart,
        endDate: currentEnd,
      );

      final previousExpenses = await SupabaseService.getExpensesByDateRange(
        userId: currentUserId,
        startDate: previousStart,
        endDate: previousEnd,
      );

      final currentTotal = currentExpenses.fold(
        0.0,
        (sum, expense) => sum + expense.amount,
      );
      final previousTotal = previousExpenses.fold(
        0.0,
        (sum, expense) => sum + expense.amount,
      );

      emit(
        ComparisonDataLoaded(
          currentPeriodExpenses: currentExpenses,
          previousPeriodExpenses: previousExpenses,
          currentTotal: currentTotal,
          previousTotal: previousTotal,
          comparisonType: event.comparisonType,
        ),
      );
    } catch (e) {
      emit(ExpenseError('Failed to load comparison data: $e'));
    }
  }

  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      // Add expense
      await SupabaseService.addExpense(event.expense);

      // Only deduct from account if accountId is provided
      if (event.accountId != null && event.accountId!.isNotEmpty) {
        // Get the specific account
        final accounts = await SupabaseService.getAccounts(userId: userId);

        try {
          final account = accounts.firstWhere(
            (acc) => acc.id == event.accountId,
          );

          // Calculate new balance
          final newBalance = account.balance - event.expense.amount;

          // Update account balance (allow negative balance)
          await SupabaseService.updateAccountBalance(
            accountId: event.accountId!,
            newBalance: newBalance,
          );
        } catch (e) {
          // Account not found, continue without updating balance
          print('Account not found or error updating balance: $e');
        }
      }

      add(LoadExpenses()); // Refresh expenses
    } catch (e) {
      emit(ExpenseError('Failed to add expense: $e'));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await SupabaseService.deleteExpense(event.expenseId);
      add(RefreshExpenses());
    } catch (e) {
      emit(ExpenseError('Failed to delete expense: $e'));
    }
  }

  Future<void> _onRefreshExpenses(
    RefreshExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      add(LoadExpenses(month: (state as ExpenseLoaded).currentMonth));
    } else {
      add(LoadExpenses());
    }
  }
}
