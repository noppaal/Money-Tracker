import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_item.dart';
import '../../../providers/finance_provider.dart';

class EditTransactionDialog extends StatefulWidget {
  final TransactionItem transaction;

  const EditTransactionDialog({super.key, required this.transaction});

  static Future<void> show(BuildContext context, TransactionItem transaction) {
    return showDialog(
      context: context,
      builder: (ctx) => EditTransactionDialog(transaction: transaction),
    );
  }

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _type;
  late String _selectedCategoryId;
  late String _selectedWalletId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toInt().toString(),
    );
    _noteController = TextEditingController(text: widget.transaction.note);
    _type = widget.transaction.type;
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedWalletId = widget.transaction.walletId;
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _saveChanges() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal harus lebih dari 0'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final updated = widget.transaction.copyWith(
      type: _type,
      amount: amount,
      categoryId: _selectedCategoryId,
      walletId: _selectedWalletId,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    final success = await context.read<FinanceProvider>().updateTransaction(updated);
    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_type == 'income' ? 'Pemasukan' : 'Pengeluaran'} berhasil diperbarui'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final availableCategories = _type == 'income'
        ? provider.incomeCategories
        : provider.expenseCategories;
    final wallets = provider.wallets;

    // Safety check: ensure _selectedCategoryId is in availableCategories
    final categoryExists = availableCategories.any((c) => c.id == _selectedCategoryId);
    final effectiveCategoryId = categoryExists
        ? _selectedCategoryId
        : (availableCategories.isNotEmpty ? availableCategories.first.id : _selectedCategoryId);

    // Safety check: ensure _selectedWalletId is in wallets
    final walletExists = wallets.any((w) => w.id == _selectedWalletId);
    final effectiveWalletId = walletExists
        ? _selectedWalletId
        : (wallets.isNotEmpty ? wallets.first.id : _selectedWalletId);

    final isIncome = _type == 'income';
    final accentColor = isIncome ? const Color(0xFF10B981) : AppColors.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Edit Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type toggle (Pengeluaran vs Pemasukan)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_type != 'expense') {
                          setState(() {
                            _type = 'expense';
                            if (provider.expenseCategories.isNotEmpty) {
                              _selectedCategoryId = provider.expenseCategories.first.id;
                            }
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isTypeIncome
                              ? const Color(0xFFEF4444)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 15,
                              color: !_isTypeIncome ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: !_isTypeIncome ? Colors.white : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_type != 'income') {
                          setState(() {
                            _type = 'income';
                            if (provider.incomeCategories.isNotEmpty) {
                              _selectedCategoryId = provider.incomeCategories.first.id;
                            }
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isTypeIncome
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 15,
                              color: _isTypeIncome ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isTypeIncome ? Colors.white : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nominal (Rp)',
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: effectiveCategoryId,
              decoration: InputDecoration(
                labelText: isIncome ? 'Sumber Pemasukan' : 'Pos Anggaran',
              ),
              items: availableCategories.map((cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Row(
                    children: [
                      Icon(cat.iconData, color: cat.color, size: 18),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategoryId = val);
              },
            ),
            const SizedBox(height: 14),

            // Wallet Dropdown
            if (wallets.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: effectiveWalletId,
                decoration: const InputDecoration(labelText: 'Dompet'),
                items: wallets.map((w) {
                  return DropdownMenuItem(
                    value: w.id,
                    child: Row(
                      children: [
                        Icon(w.iconData, color: w.color, size: 18),
                        const SizedBox(width: 8),
                        Text(w.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedWalletId = val);
                },
              ),
              const SizedBox(height: 14),
            ],

            // Note Input
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Catatan',
                hintText: isIncome ? 'Misal: Gaji bulan ini' : 'Misal: Makan Siang',
              ),
            ),
            const SizedBox(height: 14),

            // Date Button
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(DateFormatter.formatShort(_selectedDate)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saveChanges,
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  bool get _isTypeIncome => _type == 'income';
}
