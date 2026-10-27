import 'budget_category.dart';
import 'wallet.dart';

class TransactionItem {
  final String id;
  final String categoryId;
  final String walletId;
  final String type; // 'expense' or 'income'
  final double amount;
  final DateTime date;
  final String note;
  final DateTime createdAt;

  // Joined data for display
  final BudgetCategory? category;
  final Wallet? wallet;

  const TransactionItem({
    required this.id,
    required this.categoryId,
    this.walletId = 'wallet_cash',
    this.type = 'expense',
    required this.amount,
    required this.date,
    this.note = '',
    required this.createdAt,
    this.category,
    this.wallet,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type != 'income';

  TransactionItem copyWith({
    String? id,
    String? categoryId,
    String? walletId,
    String? type,
    double? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    BudgetCategory? category,
    Wallet? wallet,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      wallet: wallet ?? this.wallet,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'wallet_id': walletId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionItem.fromMap(
    Map<String, dynamic> map, {
    BudgetCategory? category,
    Wallet? wallet,
  }) {
    return TransactionItem(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      walletId: (map['wallet_id'] as String?) ?? 'wallet_cash',
      type: (map['type'] as String?) ?? 'expense',
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      category: category,
      wallet: wallet,
    );
  }
}
