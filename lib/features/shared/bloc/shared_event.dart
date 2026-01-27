import 'package:equatable/equatable.dart';

abstract class SharedEvent extends Equatable {
  const SharedEvent();

  @override
  List<Object> get props => [];
}

class LoadGroups extends SharedEvent {}

class CreateGroup extends SharedEvent {
  final String name;

  const CreateGroup(this.name);

  @override
  List<Object> get props => [name];
}

class JoinGroup extends SharedEvent {
  final String inviteCode;

  const JoinGroup(this.inviteCode);

  @override
  List<Object> get props => [inviteCode];
}

class LoadGroupDetails extends SharedEvent {
  final String groupId;

  const LoadGroupDetails(this.groupId);

  @override
  List<Object> get props => [groupId];
}

class AddSharedExpense extends SharedEvent {
  final String groupId;
  final String description;
  final double amount;
  final String category;
  final Map<String, double> splits;

  const AddSharedExpense({
    required this.groupId,
    required this.description,
    required this.amount,
    required this.category,
    required this.splits,
  });

  @override
  List<Object> get props => [groupId, description, amount, category, splits];
}

class LoadExpenseSplits extends SharedEvent {
  final String expenseId;

  const LoadExpenseSplits(this.expenseId);

  @override
  List<Object> get props => [expenseId];
}

class UpdateSplitStatus extends SharedEvent {
  final int splitId;
  final String expenseId;
  final String status;

  const UpdateSplitStatus({
    required this.splitId,
    required this.expenseId,
    required this.status,
  });

  @override
  List<Object> get props => [splitId, expenseId, status];
}
