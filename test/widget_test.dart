import 'package:flutter_test/flutter_test.dart';
import 'package:moneytracker/core/utils/currency_formatter.dart';
import 'package:moneytracker/data/models/wallet.dart';

void main() {
  group('Wallet Model & Logic Tests', () {
    test('Default wallets have correct initial properties', () {
      final defaults = Wallet.defaultWallets;
      expect(defaults.length, 3);
      expect(defaults[0].name, 'Dompet Tunai');
      expect(defaults[0].isDefault, true);
      expect(defaults[1].name, 'Rekening Bank (BCA)');
      expect(defaults[2].name, 'E-Wallet (GoPay)');
    });

    test('Wallet toMap and fromMap serialization & balance computation', () {
      final wallet = Wallet(
        id: 'test_wallet_1',
        name: 'Kantong Jajan',
        initialBalance: 500000,
        spentAmount: 150000,
        colorValue: 0xFF10B981,
        iconCodePoint: 0xe84f,
        createdAt: DateTime(2026, 1, 1),
        isDefault: false,
      );

      expect(wallet.currentBalance, 350000);

      final map = wallet.toMap();
      expect(map['id'], 'test_wallet_1');
      expect(map['name'], 'Kantong Jajan');
      expect(map['initial_balance'], 500000);

      final fromMapWallet = Wallet.fromMap(map, spent: 150000);
      expect(fromMapWallet.id, wallet.id);
      expect(fromMapWallet.name, wallet.name);
      expect(fromMapWallet.initialBalance, wallet.initialBalance);
      expect(fromMapWallet.currentBalance, 350000);
      expect(fromMapWallet.spentAmount, 150000);
      expect(fromMapWallet.isDefault, false);
    });

    test('CurrencyFormatter formats IDR correctly', () {
      expect(CurrencyFormatter.format(500000), 'Rp500.000');
      expect(CurrencyFormatter.format(0), 'Rp0');
    });
  });
}
