class IncomeModel {
  final String? id;
  final String userId;
  final String accountName;
  final double amount;
  final String source; // Salary, Business, Investment, etc.
  final DateTime date;
  final String? description;

  IncomeModel({
    this.id,
    required this.userId,
    required this.accountName,
    required this.amount,
    required this.source,
    required this.date,
    this.description,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: json['id'],
      userId: json['user_id'],
      accountName: json['account_name'],
      amount: (json['amount'] as num).toDouble(),
      source: json['source'],
      date: DateTime.parse(json['date']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'account_name': accountName,
      'amount': amount,
      'source': source,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  IncomeModel copyWith({
    String? id,
    String? userId,
    String? accountName,
    double? amount,
    String? source,
    DateTime? date,
    String? description,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountName: accountName ?? this.accountName,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}

class AccountModel {
  final String? id;
  final String userId;
  final String accountName;
  final double balance;
  final DateTime createdAt;

  AccountModel({
    this.id,
    required this.userId,
    required this.accountName,
    required this.balance,
    required this.createdAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      userId: json['user_id'],
      accountName: json['account_name'],
      balance: (json['balance'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'account_name': accountName,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
    };
  }
}