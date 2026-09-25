import 'package:equatable/equatable.dart';

class SharedExpenseModel extends Equatable {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidBy; // User ID
  final DateTime date;
  final String category;
  final String? payerName;

  const SharedExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.date,
    required this.category,
    this.payerName,
  });

  factory SharedExpenseModel.fromJson(Map<String, dynamic> json, {String? payerName}) {
    return SharedExpenseModel(
      id: json['id'],
      groupId: json['group_id'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paid_by'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      payerName: payerName ?? json['payer_name'],
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
    payerName,
  ];
}

class ExpenseSplit extends Equatable {
  final int id; // Added ID
  final String expenseId;
  final String userId;
  final double amount;
  final String status; // 'pending' or 'paid'
  final String? userName;

  const ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    this.status = 'pending',
    this.userName,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json, {String? userName}) {
    return ExpenseSplit(
      id: json['id'],
      expenseId: json['expense_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] ?? 'pending',
      userName: userName ?? json['user_name'],
    );
  }

  @override
  List<Object?> get props => [id, expenseId, userId, amount, status, userName];
}
