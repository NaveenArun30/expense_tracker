import '../../../model/expense_model.dart';

abstract class ExpenseState {}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final List<ExpenseModel> expenses;
  final double totalAmount;
  final Map<String, double> categoryTotals;
  final DateTime currentMonth;

  ExpenseLoaded({
    required this.expenses,
    required this.totalAmount,
    required this.categoryTotals,
    required this.currentMonth,
  });
}

class YearlyExpenseLoaded extends ExpenseState {
  final List<ExpenseModel> expenses;
  final Map<int, double> monthlyTotals; // month -> total amount
  final Map<String, double> categoryTotals;
  final int year;
  final double totalAmount;

  YearlyExpenseLoaded({
    required this.expenses,
    required this.monthlyTotals,
    required this.categoryTotals,
    required this.year,
    required this.totalAmount,
  });
}

class ComparisonDataLoaded extends ExpenseState {
  final List<ExpenseModel> currentPeriodExpenses;
  final List<ExpenseModel> previousPeriodExpenses;
  final double currentTotal;
  final double previousTotal;
  final String comparisonType;

  ComparisonDataLoaded({
    required this.currentPeriodExpenses,
    required this.previousPeriodExpenses,
    required this.currentTotal,
    required this.previousTotal,
    required this.comparisonType,
  });
}

class ExpenseError extends ExpenseState {
  final String message;
  ExpenseError(this.message);
}

