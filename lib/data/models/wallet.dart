import 'package:flutter/material.dart';

class Wallet {
  final String id;
  final String name;
  final double initialBalance;
  final int iconCodePoint;
  final String? iconFontFamily;
  final int colorValue;
  final DateTime createdAt;
  final bool isDefault;

  // Computed/transient from transactions
  final double spentAmount;

  const Wallet({
    required this.id,
    required this.name,
    required this.initialBalance,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.colorValue,
    required this.createdAt,
    this.isDefault = false,
    this.spentAmount = 0.0,
  });

  IconData get iconData => IconData(
        iconCodePoint,
        fontFamily: iconFontFamily ?? 'MaterialIcons',
      );

  Color get color => Color(colorValue);

  double get currentBalance => initialBalance - spentAmount;

  Wallet copyWith({
    String? id,
    String? name,
    double? initialBalance,
    int? iconCodePoint,
    String? iconFontFamily,
    int? colorValue,
    DateTime? createdAt,
    bool? isDefault,
    double? spentAmount,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initial_balance': initialBalance,
      'icon_code_point': iconCodePoint,
      'icon_font_family': iconFontFamily,
      'color_value': colorValue,
      'created_at': createdAt.toIso8601String(),
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map, {double spent = 0.0}) {
    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      initialBalance: (map['initial_balance'] as num).toDouble(),
      iconCodePoint: map['icon_code_point'] as int,
      iconFontFamily: map['icon_font_family'] as String?,
      colorValue: map['color_value'] as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      isDefault: (map['is_default'] as int?) == 1,
      spentAmount: spent,
    );
  }

  static List<Wallet> get defaultWallets => [
        Wallet(
          id: 'wallet_cash',
          name: 'Dompet Tunai',
          initialBalance: 2500000.0,
          iconCodePoint: Icons.wallet_rounded.codePoint,
          colorValue: 0xFF10B981, // Emerald
          createdAt: DateTime.now(),
          isDefault: true,
        ),
        Wallet(
          id: 'wallet_bank',
          name: 'Rekening Bank (BCA)',
          initialBalance: 2000000.0,
          iconCodePoint: Icons.account_balance_rounded.codePoint,
          colorValue: 0xFF6366F1, // Indigo
          createdAt: DateTime.now(),
          isDefault: false,
        ),
        Wallet(
          id: 'wallet_ewallet',
          name: 'E-Wallet (GoPay)',
          initialBalance: 500000.0,
          iconCodePoint: Icons.phone_android_rounded.codePoint,
          colorValue: 0xFFF59E0B, // Amber
          createdAt: DateTime.now(),
          isDefault: false,
        ),
      ];
}
