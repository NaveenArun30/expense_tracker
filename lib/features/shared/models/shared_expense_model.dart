import 'package:equatable/equatable.dart';

class SharedExpenseModel extends Equatable {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidBy; // User ID
  final DateTime date;
  final String category;

  const SharedExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.date,
    required this.category,
  });

  factory SharedExpenseModel.fromJson(Map<String, dynamic> json) {
    return SharedExpenseModel(
      id: json['id'],
      groupId: json['group_id'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paid_by'],
      date: DateTime.parse(json['date']),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'description': description,
      'amount': amount,
      'paid_by': paidBy,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    description,
    amount,
    paidBy,
    date,
    category,
  ];
}

class ExpenseSplit extends Equatable {
  final int id; // Added ID
  final String expenseId;
  final String userId;
  final double amount;
  final String status; // 'pending' or 'paid'

  const ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    this.status = 'pending',
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'],
      expenseId: json['expense_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] ?? 'pending',
    );
  }

  @override
  List<Object?> get props => [id, expenseId, userId, amount, status];
}
