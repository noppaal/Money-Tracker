import 'budget_category.dart';

class TransactionItem {
  final String id;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String note;
  final DateTime createdAt;

  // Joined category data for display
  final BudgetCategory? category;

  const TransactionItem({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.note = '',
    required this.createdAt,
    this.category,
  });

  TransactionItem copyWith({
    String? id,
    String? categoryId,
    double? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    BudgetCategory? category,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map, {BudgetCategory? category}) {
    return TransactionItem(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      category: category,
    );
  }
}
