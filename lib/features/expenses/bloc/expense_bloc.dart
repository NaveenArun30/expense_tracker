import 'package:flutter_bloc/flutter_bloc.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc() : super(ExpenseInitial()) {
    on<LoadExpenses>((event, emit) {
      emit(ExpenseLoaded([
        {"title": "Coffee", "amount": 5.0},
        {"title": "Groceries", "amount": 20.0},
      ]));
    });

    on<AddExpense>((event, emit) {
      if (state is ExpenseLoaded) {
        final current = List<Map<String, dynamic>>.from((state as ExpenseLoaded).expenses);
        current.add({"title": event.title, "amount": event.amount});
        emit(ExpenseLoaded(current));
      }
    });
  }
}
