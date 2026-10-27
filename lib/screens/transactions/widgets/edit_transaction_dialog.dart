import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
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
  late String _selectedCategoryId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toInt().toString(),
    );
    _noteController = TextEditingController(text: widget.transaction.note);
    _selectedCategoryId = widget.transaction.categoryId;
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
      amount: amount,
      categoryId: _selectedCategoryId,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    final success = await context.read<FinanceProvider>().updateTransaction(updated);
    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil diperbarui'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<FinanceProvider>().categories;

    return AlertDialog(
      title: const Text('Edit Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 14),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Pos Anggaran'),
              items: categories.map((cat) {
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

            // Note Input
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                hintText: 'Misal: Makan Siang',
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
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
