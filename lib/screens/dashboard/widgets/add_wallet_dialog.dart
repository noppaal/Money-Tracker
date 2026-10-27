import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/wallet.dart';
import '../../../providers/finance_provider.dart';

class AddWalletDialog extends StatefulWidget {
  final Wallet? wallet;

  const AddWalletDialog({super.key, this.wallet});

  static Future<void> show(BuildContext context, {Wallet? wallet}) {
    return showDialog(
      context: context,
      builder: (ctx) => AddWalletDialog(wallet: wallet),
    );
  }

  @override
  State<AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends State<AddWalletDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late int _selectedColorValue;
  late int _selectedIconCodePoint;

  static const List<int> _palette = [
    0xFF10B981, // Emerald
    0xFF0D9488, // Teal
    0xFF6366F1, // Indigo
    0xFF3B82F6, // Blue
    0xFFF59E0B, // Amber
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
    0xFFF97316, // Orange
  ];

  static final List<IconData> _icons = [
    Icons.wallet_rounded,
    Icons.account_balance_rounded,
    Icons.payments_rounded,
    Icons.credit_card_rounded,
    Icons.phone_android_rounded,
    Icons.savings_rounded,
    Icons.attach_money_rounded,
    Icons.qr_code_2_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _nameController = TextEditingController(text: w?.name ?? '');
    _balanceController = TextEditingController(
      text: w != null ? w.initialBalance.toInt().toString() : '1000000',
    );
    _selectedColorValue = w?.colorValue ?? _palette.first;
    _selectedIconCodePoint = w?.iconCodePoint ?? _icons.first.codePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dompet tidak boleh kosong')),
      );
      return;
    }

    final balance = CurrencyFormatter.parse(_balanceController.text);
    final finance = context.read<FinanceProvider>();
    HapticFeedback.mediumImpact();

    if (widget.wallet != null) {
      final updated = widget.wallet!.copyWith(
        name: name,
        initialBalance: balance,
        colorValue: _selectedColorValue,
        iconCodePoint: _selectedIconCodePoint,
      );
      await finance.updateWallet(updated);
    } else {
      await finance.addWallet(
        name: name,
        initialBalance: balance,
        colorValue: _selectedColorValue,
        iconCodePoint: _selectedIconCodePoint,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.wallet != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(_selectedColorValue).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      IconData(_selectedIconCodePoint, fontFamily: 'MaterialIcons'),
                      color: Color(_selectedColorValue),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Ubah Dompet' : 'Tambah Dompet',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Perbarui detail dompet'
                              : 'Buat pos rekening atau dompet baru',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name Field
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Dompet',
                  hintText: 'Misal: BCA, GoPay, Dompet Tunai',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // Initial Balance Field
              TextField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saldo Awal / Pagu',
                  hintText: '0',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 18),

              // Color Selector
              const Text(
                'Warna Identitas',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _palette.map((colorVal) {
                  final isSelected = _selectedColorValue == colorVal;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedColorValue = colorVal;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(colorVal).withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Icon Selector
              const Text(
                'Pilih Ikon',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((icon) {
                  final isSelected = _selectedIconCodePoint == icon.codePoint;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedIconCodePoint = icon.codePoint;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColorValue).withOpacity(0.2)
                            : (isDark ? AppColors.darkCardElevated : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Color(_selectedColorValue)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? Color(_selectedColorValue)
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Color(_selectedColorValue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(isEditing ? 'Simpan Perubahan' : 'Buat Dompet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
