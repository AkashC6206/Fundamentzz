class Expense {
  final String id;
  final String title;
  final String category; // 'Raw Materials', 'Rent', 'Electricity', 'Staff Salary', 'Maintenance', 'Other'
  final double amount;
  final String paymentMode; // 'Cash', 'UPI', 'Bank Transfer', 'Card'
  final DateTime date;
  final String notes;

  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    this.paymentMode = 'Cash',
    required this.date,
    this.notes = '',
  });

  Expense copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    String? paymentMode,
    DateTime? date,
    String? notes,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
