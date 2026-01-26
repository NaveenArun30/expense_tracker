import '../../../model/income_model.dart';

abstract class IncomeEvent {}

// Account Events
class LoadAccounts extends IncomeEvent {}

class AddAccount extends IncomeEvent {
  final AccountModel account;
  AddAccount(this.account);
}

class DeleteAccount extends IncomeEvent {
  final String accountId;
  DeleteAccount(this.accountId);
}

class UpdateAccountBalance extends IncomeEvent {
  final String accountId;
  final double newBalance;
  UpdateAccountBalance({required this.accountId, required this.newBalance});
}

// Income Events
class LoadIncome extends IncomeEvent {
  final DateTime? month;
  LoadIncome({this.month});
}

class LoadAllIncome extends IncomeEvent {}

class LoadIncomeByDateRange extends IncomeEvent {
  final DateTime startDate;
  final DateTime endDate;
  LoadIncomeByDateRange({required this.startDate, required this.endDate});
}

class AddIncome extends IncomeEvent {
  final IncomeModel income;
  final String accountId;
  AddIncome({required this.income, required this.accountId});
}

class DeleteIncome extends IncomeEvent {
  final String incomeId;
  DeleteIncome(this.incomeId);
}

class RefreshIncome extends IncomeEvent {}