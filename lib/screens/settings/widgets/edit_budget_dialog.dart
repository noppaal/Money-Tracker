import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/budget_category.dart';
import '../../../providers/finance_provider.dart';

class EditBudgetDialog extends StatefulWidget {
  final BudgetCategory category;

  const EditBudgetDialog({super.key, required this.category});

  static Future<void> show(BuildContext context, BudgetCategory category) {
    return showDialog(
      context: context,
      builder: (ctx) => EditBudgetDialog(category: category),
    );
  }

  @override
  State<EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<EditBudgetDialog> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.category.allocatedAmount.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final newAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (newAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagu anggaran tidak boleh minus'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final success = await context.read<FinanceProvider>().updateCategoryBudget(
          widget.category.id,
          newAmount,
        );

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pagu "${widget.category.name}" diubah menjadi ${CurrencyFormatter.format(newAmount)}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cat.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cat.iconData, color: cat.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ubah Pagu ${cat.name}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentukan batas anggaran bulanan untuk pos ini:',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Pagu Bulanan',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 12),
          // Quick adjustments buttons
          Row(
            children: [
              _quickButton('+100rb', 100000),
              const SizedBox(width: 8),
              _quickButton('+250rb', 250000),
              const SizedBox(width: 8),
              _quickButton('+500rb', 50000),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saveBudget,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _quickButton(String text, double addAmount) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
        onPressed: () {
          final current = double.tryParse(_amountController.text) ?? 0.0;
          setState(() {
            _amountController.text = (current + addAmount).toInt().toString();
          });
        },
        child: Text(text, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
