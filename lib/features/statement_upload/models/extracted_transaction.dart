class ExtractedTransaction {
  final String id;
  String title;
  double amount;
  DateTime date;
  String category;
  bool isCredit; // true = Credit (Income), false = Debit (Expense)
  bool isSelected;
  String? rawDescription;
  String? accountId;

  ExtractedTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isCredit,
    this.isSelected = true,
    this.rawDescription,
    this.accountId,
  });

  ExtractedTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    bool? isCredit,
    bool? isSelected,
    String? rawDescription,
  }) {
    return ExtractedTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      isCredit: isCredit ?? this.isCredit,
      isSelected: isSelected ?? this.isSelected,
      rawDescription: rawDescription ?? this.rawDescription,
    );
  }
}
