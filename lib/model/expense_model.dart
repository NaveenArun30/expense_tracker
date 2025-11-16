class ExpenseModel {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;
  final String userId;

  ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    required this.userId,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'Other',
      description: json['description'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      userId: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'user_id': userId,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? userId,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      userId: userId ?? this.userId,
    );
  }
}

