import '../../../model/expense_model.dart';

abstract class ExpenseEvent {}

class LoadExpenses extends ExpenseEvent {
  final DateTime? month;
  LoadExpenses({this.month});
}

class LoadAllExpenses extends ExpenseEvent {}

class LoadExpensesByDateRange extends ExpenseEvent {
  final DateTime startDate;
  final DateTime endDate;
  LoadExpensesByDateRange({required this.startDate, required this.endDate});
}

class LoadYearlyExpenses extends ExpenseEvent {
  final int year;
  LoadYearlyExpenses({required this.year});
}

class AddExpense extends ExpenseEvent {
  final ExpenseModel expense;
  AddExpense(this.expense);
}

class DeleteExpense extends ExpenseEvent {
  final String expenseId;
  DeleteExpense(this.expenseId);
}

class RefreshExpenses extends ExpenseEvent {}

class LoadComparisonData extends ExpenseEvent {
  final String comparisonType; // 'year', 'month'
  LoadComparisonData({required this.comparisonType});
}