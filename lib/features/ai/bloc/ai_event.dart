import 'package:equatable/equatable.dart';
import '../../../model/expense_model.dart';
import '../../../model/income_model.dart';

abstract class AiEvent extends Equatable {
  const AiEvent();

  @override
  List<Object?> get props => [];
}

class GenerateInsights extends AiEvent {
  final List<ExpenseModel> expenses;
  final List<IncomeModel> income;
  final DateTime startDate;
  final DateTime endDate;

  const GenerateInsights({
    required this.expenses,
    required this.income,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [expenses, income, startDate, endDate];
}

class SendChatMessage extends AiEvent {
  final String message;
  final List<ExpenseModel> expenses;
  final List<IncomeModel> income;

  const SendChatMessage({
    required this.message,
    required this.expenses,
    required this.income,
  });

  @override
  List<Object?> get props => [message, expenses, income];
}
