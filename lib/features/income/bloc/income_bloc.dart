import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
  import '../../../services/supabase_service.dart';
import 'income_event.dart';
import 'income_state.dart';

class IncomeBloc extends Bloc<IncomeEvent, IncomeState> {
  String get userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  IncomeBloc() : super(IncomeInitial()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<AddAccount>(_onAddAccount);
    on<DeleteAccount>(_onDeleteAccount);
    on<UpdateAccountBalance>(_onUpdateAccountBalance);
    on<LoadIncome>(_onLoadIncome);
    on<LoadAllIncome>(_onLoadAllIncome);
    on<LoadIncomeByDateRange>(_onLoadIncomeByDateRange);
    on<AddIncome>(_onAddIncome);
    on<DeleteIncome>(_onDeleteIncome);
    on<RefreshIncome>(_onRefreshIncome);
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<IncomeState> emit,
  ) async {
    emit(IncomeLoading());
    try {
      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        emit(IncomeError('User not authenticated'));
        return;
      }

      final accounts = await SupabaseService.getAccounts(
        userId: currentUserId,
      );

      final totalBalance = accounts.fold(
        0.0,
        (sum, account) => sum + account.balance,
      );

      emit(
        IncomeLoaded(
          incomes: [],
          accounts: accounts,
          totalIncome: 0,
          totalBalance: totalBalance,
          sourceTotals: {},
          currentMonth: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(IncomeError('Failed to load accounts: $e'));
    }
  }

  Future<void> _onAddAccount(
    AddAccount event,
    Emitter<IncomeState> emit,
  ) async {
    try {
      await SupabaseService.addAccount(event.account);
      add(LoadIncome());
    } catch (e) {
      emit(IncomeError('Failed to add account: $e'));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<IncomeState> emit,
  ) async {
    try {
      await SupabaseService.deleteAccount(event.accountId);
      add(RefreshIncome());
    } catch (e) {
      emit(IncomeError('Failed to delete account: $e'));
    }
  }

  Future<void> _onUpdateAccountBalance(
    UpdateAccountBalance event,
    Emitter<IncomeState> emit,
  ) async {
    try {
      await SupabaseService.updateAccountBalance(
        accountId: event.accountId,
        newBalance: event.newBalance,
      );
      add(RefreshIncome());
    } catch (e) {
      emit(IncomeError('Failed to update account balance: $e'));
    }
  }

  Future<void> _onLoadIncome(
    LoadIncome event,
    Emitter<IncomeState> emit,
  ) async {
    emit(IncomeLoading());
    try {
      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        emit(IncomeError('User not authenticated'));
        return;
      }

      final month = event.month ?? DateTime.now();
      final incomes = await SupabaseService.getMonthlyIncome(
        userId: currentUserId,
        month: month,
      );

      final accounts = await SupabaseService.getAccounts(
        userId: currentUserId,
      );

      final sourceTotals = await SupabaseService.getSourceWiseIncome(
        userId: currentUserId,
        month: month,
      );

      final totalIncome = incomes.fold(
        0.0,
        (sum, income) => sum + income.amount,
      );

      final totalBalance = accounts.fold(
        0.0,
        (sum, account) => sum + account.balance,
      );

      emit(
        IncomeLoaded(
          incomes: incomes,
          accounts: accounts,
          totalIncome: totalIncome,
          totalBalance: totalBalance,
          sourceTotals: sourceTotals,
          currentMonth: month,
        ),
      );
    } catch (e) {
      emit(IncomeError('Failed to load income: $e'));
    }
  }

  Future<void> _onLoadAllIncome(
    LoadAllIncome event,
    Emitter<IncomeState> emit,
  ) async {
    emit(IncomeLoading());
    try {
      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        emit(IncomeError('User not authenticated'));
        return;
      }

      final incomes = await SupabaseService.getAllIncome(
        userId: currentUserId,
      );

      final accounts = await SupabaseService.getAccounts(
        userId: currentUserId,
      );

      final sourceTotals = <String, double>{};
      for (var income in incomes) {
        sourceTotals[income.source] =
            (sourceTotals[income.source] ?? 0) + income.amount;
      }

      final totalIncome = incomes.fold(
        0.0,
        (sum, income) => sum + income.amount,
      );

      final totalBalance = accounts.fold(
        0.0,
        (sum, account) => sum + account.balance,
      );

      emit(
        IncomeLoaded(
          incomes: incomes,
          accounts: accounts,
          totalIncome: totalIncome,
          totalBalance: totalBalance,
          sourceTotals: sourceTotals,
          currentMonth: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(IncomeError('Failed to load all income: $e'));
    }
  }

  Future<void> _onLoadIncomeByDateRange(
    LoadIncomeByDateRange event,
    Emitter<IncomeState> emit,
  ) async {
    emit(IncomeLoading());
    try {
      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        emit(IncomeError('User not authenticated'));
        return;
      }

      final incomes = await SupabaseService.getIncomeByDateRange(
        userId: currentUserId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      final accounts = await SupabaseService.getAccounts(
        userId: currentUserId,
      );

      final sourceTotals = <String, double>{};
      for (var income in incomes) {
        sourceTotals[income.source] =
            (sourceTotals[income.source] ?? 0) + income.amount;
      }

      final totalIncome = incomes.fold(
        0.0,
        (sum, income) => sum + income.amount,
      );

      final totalBalance = accounts.fold(
        0.0,
        (sum, account) => sum + account.balance,
      );

      emit(
        IncomeLoaded(
          incomes: incomes,
          accounts: accounts,
          totalIncome: totalIncome,
          totalBalance: totalBalance,
          sourceTotals: sourceTotals,
          currentMonth: event.startDate,
        ),
      );
    } catch (e) {
      emit(IncomeError('Failed to load income by date range: $e'));
    }
  }

  Future<void> _onAddIncome(
    AddIncome event,
    Emitter<IncomeState> emit,
  ) async {
    try {
      // Add income
      await SupabaseService.addIncome(event.income);

      // Update account balance
      final accounts = await SupabaseService.getAccounts(userId: userId);
      final account = accounts.firstWhere((acc) => acc.id == event.accountId);
      final newBalance = account.balance + event.income.amount;
      
      await SupabaseService.updateAccountBalance(
        accountId: event.accountId,
        newBalance: newBalance,
      );

      add(LoadIncome());
    } catch (e) {
      emit(IncomeError('Failed to add income: $e'));
    }
  }

  Future<void> _onDeleteIncome(
    DeleteIncome event,
    Emitter<IncomeState> emit,
  ) async {
    try {
      await SupabaseService.deleteIncome(event.incomeId);
      add(RefreshIncome());
    } catch (e) {
      emit(IncomeError('Failed to delete income: $e'));
    }
  }

  Future<void> _onRefreshIncome(
    RefreshIncome event,
    Emitter<IncomeState> emit,
  ) async {
    if (state is IncomeLoaded) {
      add(LoadIncome(month: (state as IncomeLoaded).currentMonth));
    } else {
      add(LoadIncome());
    }
  }
}