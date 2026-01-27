import 'package:equatable/equatable.dart';
import '../models/group_model.dart';
import '../models/shared_expense_model.dart';

abstract class SharedState extends Equatable {
  const SharedState();

  @override
  List<Object?> get props => [];
}

class SharedInitial extends SharedState {}

class SharedLoading extends SharedState {}

class GroupsLoaded extends SharedState {
  final List<GroupModel> groups;

  const GroupsLoaded(this.groups);

  @override
  List<Object> get props => [groups];
}

class GroupDetailsLoaded extends SharedState {
  final GroupModel group;
  final List<GroupMember> members;
  final List<SharedExpenseModel> expenses;

  const GroupDetailsLoaded({
    required this.group,
    required this.members,
    required this.expenses,
  });

  @override
  List<Object> get props => [group, members, expenses];
}

class SharedError extends SharedState {
  final String message;

  const SharedError(this.message);

  @override
  List<Object> get props => [message];
}

class SharedOperationSuccess extends SharedState {
  final String message;

  const SharedOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ExpenseSplitsLoaded extends SharedState {
  final SharedExpenseModel expense;
  final List<ExpenseSplit> splits;

  const ExpenseSplitsLoaded({required this.expense, required this.splits});

  @override
  List<Object> get props => [expense, splits];
}
