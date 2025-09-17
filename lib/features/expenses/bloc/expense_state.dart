abstract class ExpenseState {}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final List<Map<String, dynamic>> expenses;
  ExpenseLoaded(this.expenses);
}
