abstract class ExpenseEvent {}

class LoadExpenses extends ExpenseEvent {}

class AddExpense extends ExpenseEvent {
  final String title;
  final double amount;
  AddExpense(this.title, this.amount);
}
