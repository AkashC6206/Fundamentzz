import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.title,
    required super.category,
    required super.amount,
    super.paymentMode = 'Cash',
    required super.date,
    super.notes = '',
  });

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      title: expense.title,
      category: expense.category,
      amount: expense.amount,
      paymentMode: expense.paymentMode,
      date: expense.date,
      notes: expense.notes,
    );
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMode: (map['payment_mode'] as String?) ?? 'Cash',
      date: DateTime.parse(map['date'] as String),
      notes: (map['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'payment_mode': paymentMode,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}
