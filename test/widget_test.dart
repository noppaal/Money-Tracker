import 'package:flutter_test/flutter_test.dart';
import 'package:moneytracker/core/utils/currency_formatter.dart';
import 'package:moneytracker/data/models/wallet.dart';
import 'package:moneytracker/data/models/transaction_item.dart';

void main() {
  group('Wallet Model & Logic Tests', () {
    test('Default wallets have correct initial properties and zero balance', () {
      final defaults = Wallet.defaultWallets;
      expect(defaults.length, 3);
      expect(defaults[0].name, 'Dompet Tunai');
      expect(defaults[0].isDefault, true);
      expect(defaults[0].initialBalance, 0.0);
      expect(defaults[1].name, 'Rekening Bank (BCA)');
      expect(defaults[1].initialBalance, 0.0);
      expect(defaults[2].name, 'E-Wallet (GoPay)');
      expect(defaults[2].initialBalance, 0.0);
    });

    test('Wallet toMap and fromMap serialization & balance computation with income', () {
      final wallet = Wallet(
        id: 'test_wallet_1',
        name: 'Kantong Jajan',
        initialBalance: 500000,
        incomeAmount: 300000,
        spentAmount: 150000,
        colorValue: 0xFF10B981,
        iconCodePoint: 0xe84f,
        createdAt: DateTime(2026, 1, 1),
        isDefault: false,
      );

      // currentBalance = 500.000 + 300.000 - 150.000 = 650.000
      expect(wallet.currentBalance, 650000);

      final map = wallet.toMap();
      expect(map['id'], 'test_wallet_1');
      expect(map['name'], 'Kantong Jajan');
      expect(map['initial_balance'], 500000);

      final fromMapWallet = Wallet.fromMap(map, spent: 150000, income: 300000);
      expect(fromMapWallet.id, wallet.id);
      expect(fromMapWallet.name, wallet.name);
      expect(fromMapWallet.initialBalance, wallet.initialBalance);
      expect(fromMapWallet.incomeAmount, 300000);
      expect(fromMapWallet.spentAmount, 150000);
      expect(fromMapWallet.currentBalance, 650000);
      expect(fromMapWallet.isDefault, false);
    });

    test('CurrencyFormatter formats IDR correctly', () {
      expect(CurrencyFormatter.format(500000), 'Rp500.000');
      expect(CurrencyFormatter.format(0), 'Rp0');
    });
  });

  group('TransactionItem & Category Income Tests', () {
    test('TransactionItem handles income vs expense correctly', () {
      final expenseTx = TransactionItem(
        id: 'tx_exp_1',
        categoryId: 'cat_food',
        type: 'expense',
        amount: 25000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(expenseTx.isExpense, true);
      expect(expenseTx.isIncome, false);

      final incomeTx = TransactionItem(
        id: 'tx_inc_1',
        categoryId: 'cat_salary',
        type: 'income',
        amount: 5000000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(incomeTx.isIncome, true);
      expect(incomeTx.isExpense, false);

      final incomeMap = incomeTx.toMap();
      expect(incomeMap['type'], 'income');
      expect(incomeMap['amount'], 5000000.0);

      final fromMapTx = TransactionItem.fromMap(incomeMap);
      expect(fromMapTx.isIncome, true);
      expect(fromMapTx.amount, 5000000);
    });
  });
}
