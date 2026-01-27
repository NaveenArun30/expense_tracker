import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_model.dart';
import '../models/shared_expense_model.dart';

class SharedRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Groups
  Future<List<GroupModel>> getUserGroups() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('group_members')
        .select('groups(*)')
        .eq('user_id', userId);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((e) => GroupModel.fromJson(e['groups'])).toList();
  }

  Future<String> createGroup(String name) async {
    final userId = _supabase.auth.currentUser!.id;

    // 1. Create Group
    final groupResponse = await _supabase
        .from('groups')
        .insert({
          'name': name,
          'created_by': userId,
          'invite_code': _generateInviteCode(),
        })
        .select()
        .single();

    final group = GroupModel.fromJson(groupResponse);

    // 2. Add Creator as Admin
    await _supabase.from('group_members').insert({
      'group_id': group.id,
      'user_id': userId,
      'role': 'admin',
    });

    return group.id;
  }

  Future<void> joinGroup(String inviteCode) async {
    final userId = _supabase.auth.currentUser!.id;

    // Find group
    final groupResponse = await _supabase
        .from('groups')
        .select()
        .eq('invite_code', inviteCode)
        .single();

    final groupId = groupResponse['id'];

    // Check if already member
    final existingRef = await _supabase
        .from('group_members')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingRef != null) {
      throw Exception('Already a member of this group');
    }

    // Add Member
    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'member',
    });
  }

  // Members
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final response = await _supabase
        .from('group_members')
        .select()
        .eq('group_id', groupId);
    return (response as List).map((e) => GroupMember.fromJson(e)).toList();
  }

  // Expenses
  Future<List<SharedExpenseModel>> getGroupExpenses(String groupId) async {
    final response = await _supabase
        .from('shared_expenses')
        .select()
        .eq('group_id', groupId)
        .order('date', ascending: false);
    return (response as List)
        .map((e) => SharedExpenseModel.fromJson(e))
        .toList();
  }

  Future<void> addSharedExpense({
    required String groupId,
    required String description,
    required double amount,
    required String category,
    required Map<String, double> splits, // userId -> amount
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // 1. Add Expense
    final expenseResponse = await _supabase
        .from('shared_expenses')
        .insert({
          'group_id': groupId,
          'description': description,
          'amount': amount,
          'paid_by': userId,
          'date': DateTime.now().toIso8601String(),
          'category': category,
        })
        .select()
        .single();

    final expenseId = expenseResponse['id'];

    // 2. Add Splits
    final List<Map<String, dynamic>> splitRows = [];
    splits.forEach((uid, splitAmount) {
      splitRows.add({
        'expense_id': expenseId,
        'user_id': uid,
        'amount': splitAmount,
        // Mark the payer as 'paid', others as 'pending'
        'status': uid == userId ? 'paid' : 'pending',
      });
    });

    await _supabase.from('expense_splits').insert(splitRows);
  }

  Future<SharedExpenseModel> getSharedExpense(String expenseId) async {
    final response = await _supabase
        .from('shared_expenses')
        .select()
        .eq('id', expenseId)
        .single();
    return SharedExpenseModel.fromJson(response);
  }

  Future<List<ExpenseSplit>> getExpenseSplits(String expenseId) async {
    final response = await _supabase
        .from('expense_splits')
        .select()
        .eq('expense_id', expenseId);
    return (response as List).map((e) => ExpenseSplit.fromJson(e)).toList();
  }

  Future<void> updateSplitStatus(int splitId, String status) async {
    // We use select() to ensure the update actually happened (RLS might silently block it)
    final response = await _supabase
        .from('expense_splits')
        .update({'status': status})
        .eq('id', splitId)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception(
        'Failed to update status. You might not have permission or the split was not found.',
      );
    }
  }

  String _generateInviteCode() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  }
}
