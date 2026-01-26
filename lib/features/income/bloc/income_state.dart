import '../../../model/income_model.dart';

abstract class IncomeState {}

class IncomeInitial extends IncomeState {}

class IncomeLoading extends IncomeState {}

class IncomeLoaded extends IncomeState {
  final List<IncomeModel> incomes;
  final List<AccountModel> accounts;
  final double totalIncome;
  final double totalBalance;
  final Map<String, double> sourceTotals;
  final DateTime currentMonth;

  IncomeLoaded({
    required this.incomes,
    required this.accounts,
    required this.totalIncome,
    required this.totalBalance,
    required this.sourceTotals,
    required this.currentMonth,
  });
}

class IncomeError extends IncomeState {
  final String message;
  IncomeError(this.message);
}