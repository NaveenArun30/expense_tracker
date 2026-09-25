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

  // User Profiles Helper
  Future<Map<String, Map<String, String>>> getUserProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    try {
      final response = await _supabase
          .from('users')
          .select('user_id, name, email')
          .filter('user_id', 'in', userIds);

      final Map<String, Map<String, String>> profiles = {};
      for (var item in (response as List)) {
        final uid = item['user_id'] as String;
        profiles[uid] = {
          'name': (item['name'] as String?) ?? '',
          'email': (item['email'] as String?) ?? '',
        };
      }
      return profiles;
    } catch (e) {
      print('Error fetching user profiles: $e');
      return {};
    }
  }

  // Members
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final response = await _supabase
        .from('group_members')
        .select()
        .eq('group_id', groupId);

    final memberList = response as List;
    final userIds = memberList.map((e) => e['user_id'] as String).toList();
    final userProfiles = await getUserProfiles(userIds);
    final currentAuthUser = _supabase.auth.currentUser;

    return memberList.map((e) {
      final uid = e['user_id'] as String;
      String? name = userProfiles[uid]?['name'];
      String? email = userProfiles[uid]?['email'];

      if ((name == null || name.isEmpty) && uid == currentAuthUser?.id) {
        name = currentAuthUser?.userMetadata?['name'];
        email = currentAuthUser?.email;
      }

      return GroupMember.fromJson(
        e,
        userName: name,
        userEmail: email,
      );
    }).toList();
  }

  // Expenses
  Future<List<SharedExpenseModel>> getGroupExpenses(String groupId) async {
    final response = await _supabase
        .from('shared_expenses')
        .select()
        .eq('group_id', groupId)
        .order('date', ascending: false);

    final expenseList = response as List;
    final payerIds = expenseList.map((e) => e['paid_by'] as String).toSet().toList();
    final userProfiles = await getUserProfiles(payerIds);
    final currentAuthUser = _supabase.auth.currentUser;

    return expenseList.map((e) {
      final paidBy = e['paid_by'] as String;
      String? payerName = userProfiles[paidBy]?['name'];
      if ((payerName == null || payerName.isEmpty) && userProfiles[paidBy]?['email'] != null) {
        payerName = userProfiles[paidBy]!['email']!.split('@')[0];
      }
      if ((payerName == null || payerName.isEmpty) && paidBy == currentAuthUser?.id) {
        payerName = currentAuthUser?.userMetadata?['name'] ?? 'You';
      }
      return SharedExpenseModel.fromJson(e, payerName: payerName);
    }).toList();
  }

  Stream<List<SharedExpenseModel>> watchGroupExpenses(String groupId) {
    return _supabase
        .from('shared_expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('date', ascending: false)
        .asyncMap(
          (list) async {
            final payerIds = list.map((e) => e['paid_by'] as String).toSet().toList();
            final userProfiles = await getUserProfiles(payerIds);
            final currentAuthUser = _supabase.auth.currentUser;

            return list.map((e) {
              final paidBy = e['paid_by'] as String;
              String? payerName = userProfiles[paidBy]?['name'];
              if ((payerName == null || payerName.isEmpty) && userProfiles[paidBy]?['email'] != null) {
                payerName = userProfiles[paidBy]!['email']!.split('@')[0];
              }
              if ((payerName == null || payerName.isEmpty) && paidBy == currentAuthUser?.id) {
                payerName = currentAuthUser?.userMetadata?['name'] ?? 'You';
              }
              return SharedExpenseModel.fromJson(e, payerName: payerName);
            }).toList();
          },
        );
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

    final paidBy = response['paid_by'] as String;
    final userProfiles = await getUserProfiles([paidBy]);
    final currentAuthUser = _supabase.auth.currentUser;

    String? payerName = userProfiles[paidBy]?['name'];
    if ((payerName == null || payerName.isEmpty) && userProfiles[paidBy]?['email'] != null) {
      payerName = userProfiles[paidBy]!['email']!.split('@')[0];
    }
    if ((payerName == null || payerName.isEmpty) && paidBy == currentAuthUser?.id) {
      payerName = currentAuthUser?.userMetadata?['name'] ?? 'You';
    }

    return SharedExpenseModel.fromJson(response, payerName: payerName);
  }

  Future<List<ExpenseSplit>> getExpenseSplits(String expenseId) async {
    final response = await _supabase
        .from('expense_splits')
        .select()
        .eq('expense_id', expenseId);

    final splitList = response as List;
    final userIds = splitList.map((e) => e['user_id'] as String).toSet().toList();
    final userProfiles = await getUserProfiles(userIds);
    final currentAuthUser = _supabase.auth.currentUser;

    return splitList.map((e) {
      final uid = e['user_id'] as String;
      String? userName = userProfiles[uid]?['name'];
      if ((userName == null || userName.isEmpty) && userProfiles[uid]?['email'] != null) {
        userName = userProfiles[uid]!['email']!.split('@')[0];
      }
      if ((userName == null || userName.isEmpty) && uid == currentAuthUser?.id) {
        userName = currentAuthUser?.userMetadata?['name'] ?? 'You';
      }

      return ExpenseSplit.fromJson(e, userName: userName);
    }).toList();
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
