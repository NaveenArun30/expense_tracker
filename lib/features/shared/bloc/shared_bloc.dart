import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/shared_repository.dart';
import '../models/shared_expense_model.dart';
import 'shared_event.dart';
import 'shared_state.dart';

class SharedBloc extends Bloc<SharedEvent, SharedState> {
  final SharedRepository _repository;

  SharedBloc({required SharedRepository repository})
    : _repository = repository,
      super(SharedInitial()) {
    on<LoadGroups>(_onLoadGroups);
    on<CreateGroup>(_onCreateGroup);
    on<JoinGroup>(_onJoinGroup);
    on<LoadGroupDetails>(_onLoadGroupDetails);
    on<AddSharedExpense>(_onAddSharedExpense);
    on<LoadExpenseSplits>(_onLoadExpenseSplits);
    on<UpdateSplitStatus>(_onUpdateSplitStatus);
  }

  Future<void> _onLoadGroups(
    LoadGroups event,
    Emitter<SharedState> emit,
  ) async {
    // Only show loading if we don't already have groups loaded
    if (state is! GroupsLoaded) {
      emit(SharedLoading());
    }

    try {
      final groups = await _repository.getUserGroups();
      emit(GroupsLoaded(groups));
    } catch (e) {
      emit(SharedError(e.toString()));
    }
  }

  Future<void> _onCreateGroup(
    CreateGroup event,
    Emitter<SharedState> emit,
  ) async {
    try {
      await _repository.createGroup(event.name);
      // Reload groups without showing loading
      final groups = await _repository.getUserGroups();
      emit(GroupsLoaded(groups));
    } catch (e) {
      emit(SharedError(e.toString()));
    }
  }

  Future<void> _onJoinGroup(JoinGroup event, Emitter<SharedState> emit) async {
    try {
      await _repository.joinGroup(event.inviteCode);
      // Reload groups without showing loading
      final groups = await _repository.getUserGroups();
      emit(GroupsLoaded(groups));
    } catch (e) {
      emit(SharedError(e.toString()));
    }
  }

  Future<void> _onLoadGroupDetails(
    LoadGroupDetails event,
    Emitter<SharedState> emit,
  ) async {
    // Only show loading if:
    // 1. We don't have GroupDetailsLoaded state OR
    // 2. We have GroupDetailsLoaded but for a different group
    final currentState = state;
    if (currentState is! GroupDetailsLoaded ||
        currentState.group.id != event.groupId) {
      emit(SharedLoading());
    }

    try {
      final groups = await _repository.getUserGroups();
      final group = groups.firstWhere((g) => g.id == event.groupId);

      final members = await _repository.getGroupMembers(event.groupId);
      final expenses = await _repository.getGroupExpenses(event.groupId);

      emit(
        GroupDetailsLoaded(group: group, members: members, expenses: expenses),
      );
    } catch (e) {
      emit(SharedError(e.toString()));
    }
  }

  Future<void> _onAddSharedExpense(
    AddSharedExpense event,
    Emitter<SharedState> emit,
  ) async {
    try {
      await _repository.addSharedExpense(
        groupId: event.groupId,
        description: event.description,
        amount: event.amount,
        category: event.category,
        splits: event.splits,
      );

      // Reload group details silently (no loading state)
      final groups = await _repository.getUserGroups();
      final group = groups.firstWhere((g) => g.id == event.groupId);
      final members = await _repository.getGroupMembers(event.groupId);
      final expenses = await _repository.getGroupExpenses(event.groupId);

      emit(
        GroupDetailsLoaded(group: group, members: members, expenses: expenses),
      );
    } catch (e) {
      emit(SharedError(e.toString()));
    }
  }

  Future<void> _onLoadExpenseSplits(
    LoadExpenseSplits event,
    Emitter<SharedState> emit,
  ) async {
    // Only show loading if:
    // 1. We don't have ExpenseSplitsLoaded state OR
    // 2. We have ExpenseSplitsLoaded but for a different expense
    final currentState = state;
    if (currentState is! ExpenseSplitsLoaded ||
        currentState.expense.id != event.expenseId) {
      emit(SharedLoading());
    }

    try {
      final results = await Future.wait([
        _repository.getExpenseSplits(event.expenseId),
        _repository.getSharedExpense(event.expenseId),
      ]);

      final splits = results[0] as List<ExpenseSplit>;
      final expense = results[1] as SharedExpenseModel;

      emit(ExpenseSplitsLoaded(expense: expense, splits: splits));
    } catch (e) {
      emit(SharedError(e.toString()));
    }
  }

  Future<void> _onUpdateSplitStatus(
    UpdateSplitStatus event,
    Emitter<SharedState> emit,
  ) async {
    try {
      await _repository.updateSplitStatus(event.splitId, event.status);

      // Reload splits silently without loading state
      final results = await Future.wait([
        _repository.getExpenseSplits(event.expenseId),
        _repository.getSharedExpense(event.expenseId),
      ]);

      final splits = results[0] as List<ExpenseSplit>;
      final expense = results[1] as SharedExpenseModel;

      emit(ExpenseSplitsLoaded(expense: expense, splits: splits));
    } catch (e) {
      emit(SharedError(e.toString()));
    }
  }
}
