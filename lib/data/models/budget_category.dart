import 'package:flutter/material.dart';

class BudgetCategory {
  final String id;
  final String name;
  final String type; // 'expense' or 'income'
  final double allocatedAmount;
  final int iconCodePoint;
  final String? iconFontFamily;
  final int colorValue;
  final int sortOrder;
  final bool isDefault;

  // Transient/Computed properties
  final double spentAmount;

  const BudgetCategory({
    required this.id,
    required this.name,
    this.type = 'expense',
    required this.allocatedAmount,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.colorValue,
    this.sortOrder = 0,
    this.isDefault = false,
    this.spentAmount = 0.0,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type != 'income';

  IconData get iconData => IconData(
        iconCodePoint,
        fontFamily: iconFontFamily ?? 'MaterialIcons',
      );

  Color get color => Color(colorValue);

  double get remainingAmount => allocatedAmount - spentAmount;
  double get usageRatio => allocatedAmount > 0 ? (spentAmount / allocatedAmount) : 0.0;
  bool get isOverbudget => spentAmount > allocatedAmount;

  BudgetCategory copyWith({
    String? id,
    String? name,
    String? type,
    double? allocatedAmount,
    int? iconCodePoint,
    String? iconFontFamily,
    int? colorValue,
    int? sortOrder,
    bool? isDefault,
    double? spentAmount,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'allocated_amount': allocatedAmount,
      'icon_code_point': iconCodePoint,
      'icon_font_family': iconFontFamily,
      'color_value': colorValue,
      'sort_order': sortOrder,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory BudgetCategory.fromMap(Map<String, dynamic> map, {double spent = 0.0}) {
    return BudgetCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      type: (map['type'] as String?) ?? 'expense',
      allocatedAmount: (map['allocated_amount'] as num).toDouble(),
      iconCodePoint: map['icon_code_point'] as int,
      iconFontFamily: map['icon_font_family'] as String?,
      colorValue: map['color_value'] as int,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isDefault: (map['is_default'] as int?) == 1,
      spentAmount: spent,
    );
  }

  // Pre-configured default expense envelopes: Initial = Rp0
  static List<BudgetCategory> get defaultCategories => [
        BudgetCategory(
          id: 'savings',
          name: 'Tabungan & Investasi',
          type: 'expense',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.savings_rounded.codePoint,
          colorValue: 0xFF10B981, // Emerald
          sortOrder: 1,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'food',
          name: 'Makan & Minum',
          type: 'expense',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          colorValue: 0xFFF59E0B, // Amber / Warm Orange
          sortOrder: 2,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'laundry',
          name: 'Laundry',
          type: 'expense',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.local_laundry_service_rounded.codePoint,
          colorValue: 0xFF06B6D4, // Cyan
          sortOrder: 3,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'electricity',
          name: 'Listrik',
          type: 'expense',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.bolt_rounded.codePoint,
          colorValue: 0xFFEAB308, // Yellow
          sortOrder: 4,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'wifi',
          name: 'Wi-Fi',
          type: 'expense',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.wifi_rounded.codePoint,
          colorValue: 0xFF3B82F6, // Blue
          sortOrder: 5,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'transport',
          name: 'Transport & Pulsa',
          type: 'expense',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.directions_car_rounded.codePoint,
          colorValue: 0xFF8B5CF6, // Purple
          sortOrder: 6,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'entertainment',
          name: 'Senang-senang / Hiburan',
          type: 'expense',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.sports_esports_rounded.codePoint,
          colorValue: 0xFFEC4899, // Pink
          sortOrder: 7,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'medical',
          name: 'Dana Cadangan & Medis',
          type: 'expense',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.health_and_safety_rounded.codePoint,
          colorValue: 0xFFEF4444, // Red
          sortOrder: 8,
          isDefault: true,
        ),
      ];

  // Pre-configured default income categories
  static List<BudgetCategory> get defaultIncomeCategories => [
        BudgetCategory(
          id: 'income_salary',
          name: 'Gaji Pokok & Upah',
          type: 'income',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.payments_rounded.codePoint,
          colorValue: 0xFF10B981, // Emerald
          sortOrder: 1,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'income_bonus',
          name: 'Bonus, THR & Insentif',
          type: 'income',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.card_giftcard_rounded.codePoint,
          colorValue: 0xFFF59E0B, // Amber
          sortOrder: 2,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'income_business',
          name: 'Bisnis & Penjualan',
          type: 'income',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.storefront_rounded.codePoint,
          colorValue: 0xFF6366F1, // Indigo
          sortOrder: 3,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'income_freelance',
          name: 'Freelance & Side Job',
          type: 'income',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.laptop_mac_rounded.codePoint,
          colorValue: 0xFF06B6D4, // Cyan
          sortOrder: 4,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'income_investment',
          name: 'Investasi & Dividen',
          type: 'income',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.trending_up_rounded.codePoint,
          colorValue: 0xFF0D9488, // Teal
          sortOrder: 5,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'income_gift',
          name: 'Hadiah & Transfer Masuk',
          type: 'income',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.redeem_rounded.codePoint,
          colorValue: 0xFFEC4899, // Pink
          sortOrder: 6,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'income_other',
          name: 'Pemasukan Lainnya',
          type: 'income',
          allocatedAmount: 0.0,
          iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
          colorValue: 0xFF8B5CF6, // Purple
          sortOrder: 7,
          isDefault: true,
        ),
      ];
}
