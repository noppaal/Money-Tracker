import 'package:flutter/material.dart';

class BudgetCategory {
  final String id;
  final String name;
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
    required this.allocatedAmount,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.colorValue,
    this.sortOrder = 0,
    this.isDefault = false,
    this.spentAmount = 0.0,
  });

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
      allocatedAmount: (map['allocated_amount'] as num).toDouble(),
      iconCodePoint: map['icon_code_point'] as int,
      iconFontFamily: map['icon_font_family'] as String?,
      colorValue: map['color_value'] as int,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isDefault: (map['is_default'] as int?) == 1,
      spentAmount: spent,
    );
  }

  // Pre-configured 8 default envelopes requested: Total = Rp4.500.000
  static List<BudgetCategory> get defaultCategories => [
        BudgetCategory(
          id: 'savings',
          name: 'Tabungan & Investasi',
          allocatedAmount: 1000000.0,
          iconCodePoint: Icons.savings_rounded.codePoint,
          colorValue: 0xFF10B981, // Emerald
          sortOrder: 1,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'food',
          name: 'Makan & Minum',
          allocatedAmount: 1800000.0, // ~Rp60.000/hari
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          colorValue: 0xFFF59E0B, // Amber / Warm Orange
          sortOrder: 2,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'laundry',
          name: 'Laundry',
          allocatedAmount: 250000.0,
          iconCodePoint: Icons.local_laundry_service_rounded.codePoint,
          colorValue: 0xFF06B6D4, // Cyan
          sortOrder: 3,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'electricity',
          name: 'Listrik',
          allocatedAmount: 200000.0,
          iconCodePoint: Icons.bolt_rounded.codePoint,
          colorValue: 0xFFEAB308, // Yellow
          sortOrder: 4,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'wifi',
          name: 'Wi-Fi',
          allocatedAmount: 200000.0,
          iconCodePoint: Icons.wifi_rounded.codePoint,
          colorValue: 0xFF3B82F6, // Blue
          sortOrder: 5,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'transport',
          name: 'Transport & Pulsa',
          allocatedAmount: 400000.0,
          iconCodePoint: Icons.directions_car_rounded.codePoint,
          colorValue: 0xFF8B5CF6, // Purple
          sortOrder: 6,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'entertainment',
          name: 'Senang-senang / Hiburan',
          allocatedAmount: 400000.0,
          iconCodePoint: Icons.sports_esports_rounded.codePoint,
          colorValue: 0xFFEC4899, // Pink
          sortOrder: 7,
          isDefault: true,
        ),
        BudgetCategory(
          id: 'medical',
          name: 'Dana Cadangan & Medis',
          allocatedAmount: 250000.0,
          iconCodePoint: Icons.health_and_safety_rounded.codePoint,
          colorValue: 0xFFEF4444, // Red
          sortOrder: 8,
          isDefault: true,
        ),
      ];
}
