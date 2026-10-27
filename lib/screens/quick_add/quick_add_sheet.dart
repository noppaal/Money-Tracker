import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/finance_provider.dart';

class QuickAddSheet extends StatefulWidget {
  final String? initialCategoryId;
  final String initialType; // 'expense' or 'income'

  const QuickAddSheet({
    super.key,
    this.initialCategoryId,
    this.initialType = 'expense',
  });

  static Future<void> show(
    BuildContext context, {
    String? categoryId,
    String type = 'expense',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickAddSheet(
        initialCategoryId: categoryId,
        initialType: type,
      ),
    );
  }

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  late String _transactionType; // 'expense' or 'income'
  String _amountString = '0';
  String? _selectedCategoryId;
  String? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();

  static const List<double> _incomePresets = [
    100000.0,
    500000.0,
    1000000.0,
    2500000.0,
    5000000.0,
  ];

  static const List<String> _incomeQuickNotes = [
    'Gaji Bulanan',
    'Bonus Project',
    'Dividen & Bunga',
    'Transfer Masuk',
    'Uang Saku',
    'Hasil Jualan',
    'Freelance',
  ];

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialType;

    final finance = context.read<FinanceProvider>();
    final activeCategories = _transactionType == 'income'
        ? finance.incomeCategories
        : finance.expenseCategories;

    if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
    } else if (activeCategories.isNotEmpty) {
      if (_transactionType == 'expense') {
        final foodExists = activeCategories.any((c) => c.id == 'food');
        _selectedCategoryId = foodExists ? 'food' : activeCategories.first.id;
      } else {
        _selectedCategoryId = activeCategories.first.id;
      }
    }

    if (finance.selectedWallet != null) {
      _selectedWalletId = finance.selectedWallet!.id;
    } else if (finance.wallets.isNotEmpty) {
      _selectedWalletId = finance.wallets.first.id;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _currentAmount => double.tryParse(_amountString) ?? 0.0;

  void _onNumpadPress(String val) {
    HapticFeedback.lightImpact();
    setState(() {
      if (val == 'C') {
        _amountString = '0';
      } else if (val == 'BACK') {
        if (_amountString.length > 1) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        } else {
          _amountString = '0';
        }
      } else if (val == '000') {
        if (_amountString != '0' && _amountString.length < 9) {
          _amountString += '000';
        }
      } else {
        if (_amountString == '0') {
          _amountString = val;
        } else if (_amountString.length < 11) {
          _amountString += val;
        }
      }
    });
  }

  void _addPreset(double presetAmount) {
    HapticFeedback.mediumImpact();
    setState(() {
      final current = _currentAmount;
      final newTotal = current + presetAmount;
      _amountString = newTotal.toInt().toString();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );
      });
    }
  }

  void _switchType(String newType, FinanceProvider finance) {
    if (_transactionType == newType) return;
    HapticFeedback.selectionClick();
    setState(() {
      _transactionType = newType;
      final list = newType == 'income'
          ? finance.incomeCategories
          : finance.expenseCategories;
      if (list.isNotEmpty) {
        _selectedCategoryId = list.first.id;
      }
    });
  }

  Future<void> _saveTransaction() async {
    final amount = _currentAmount;
    final isIncome = _transactionType == 'income';

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isIncome
                ? 'Masukkan nominal pemasukan yang valid'
                : 'Masukkan nominal pengeluaran yang valid',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isIncome
                ? 'Pilih salah satu kategori pemasukan'
                : 'Pilih salah satu pos anggaran pengeluaran',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    final success = await context.read<FinanceProvider>().addTransaction(
          categoryId: _selectedCategoryId!,
          amount: amount,
          date: _selectedDate,
          type: _transactionType,
          note: _noteController.text,
          walletId: _selectedWalletId,
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIncome
                  ? 'Pemasukan ${CurrencyFormatter.format(amount)} berhasil dicatat'
                  : 'Pengeluaran ${CurrencyFormatter.format(amount)} berhasil disimpan',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = _transactionType == 'income';
    final categories = isIncome ? finance.incomeCategories : finance.expenseCategories;
    final activeThemeColor = isIncome ? const Color(0xFF10B981) : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Toggle Tabs: Pengeluaran vs Pemasukan
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _switchType('expense', finance),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !isIncome
                              ? AppColors.danger.withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: !isIncome
                              ? Border.all(color: AppColors.danger.withOpacity(0.4), width: 1.2)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_outward_rounded,
                              size: 16,
                              color: !isIncome ? AppColors.danger : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !isIncome
                                    ? AppColors.danger
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => _switchType('income', finance),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isIncome
                              ? const Color(0xFF10B981).withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isIncome
                              ? Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1.2)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: isIncome ? const Color(0xFF10B981) : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isIncome
                                    ? const Color(0xFF10B981)
                                    : (isDark ? Colors.white70 : Colors.black87),
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

            // Header Title & Date Picker Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isIncome ? 'Catat Pemasukan' : 'Catat Pengeluaran',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          DateFormatter.formatShort(_selectedDate),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Big Nominal Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeThemeColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isIncome ? 'Nominal Pemasukan' : 'Nominal Pengeluaran',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.format(_currentAmount),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: _currentAmount > 0
                            ? (isIncome ? const Color(0xFF10B981) : (isDark ? Colors.white : AppColors.primaryDark))
                            : Colors.grey,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick Preset Nominal Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (isIncome ? _incomePresets : AppConstants.quickPresets).map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text('+${CurrencyFormatter.formatCompact(preset)}'),
                      avatar: const Icon(Icons.add_rounded, size: 16),
                      backgroundColor: isDark ? AppColors.darkCardElevated : Colors.white,
                      side: BorderSide(
                        color: activeThemeColor.withOpacity(0.3),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: activeThemeColor,
                      ),
                      onPressed: () => _addPreset(preset),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Wallet Selection (Horizontal Scroll Chips)
            if (finance.wallets.isNotEmpty) ...[
              Text(
                isIncome ? 'Masuk ke Dompet' : 'Sumber Dompet',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: finance.wallets.map((w) {
                    final isSelected = _selectedWalletId == w.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              w.iconData,
                              size: 16,
                              color: isSelected ? Colors.white : w.color,
                            ),
                            const SizedBox(width: 6),
                            Text(w.name),
                          ],
                        ),
                        selectedColor: w.color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedWalletId = w.id;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Category Selection (Horizontal Scroll Chips)
            Text(
              isIncome ? 'Kategori Pemasukan' : 'Pilih Pos Anggaran',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.iconData,
                            size: 16,
                            color: isSelected ? Colors.white : cat.color,
                          ),
                          const SizedBox(width: 6),
                          Text(cat.name),
                        ],
                      ),
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedCategoryId = cat.id;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Note Input Field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: isIncome
                    ? 'Catatan pemasukan (misal: Gaji bulanan, project freelance)'
                    : 'Catatan pengeluaran (misal: Nasi Padang)',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: _noteController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _noteController.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Quick Note Suggestions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (isIncome ? _incomeQuickNotes : AppConstants.quickNotes).map((note) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _noteController.text = note;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Compact Built-In Numpad
            _buildNumpad(isDark),
            const SizedBox(height: 16),

            // Save Button
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeThemeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
              ),
              child: Text(
                isIncome ? 'Simpan Pemasukan' : 'Simpan Pengeluaran',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _numpadButton('1', isDark),
              _numpadButton('2', isDark),
              _numpadButton('3', isDark),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _numpadButton('4', isDark),
              _numpadButton('5', isDark),
              _numpadButton('6', isDark),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _numpadButton('7', isDark),
              _numpadButton('8', isDark),
              _numpadButton('9', isDark),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _numpadButton('C', isDark, isSpecial: true, color: AppColors.danger),
              _numpadButton('0', isDark),
              _numpadButton('000', isDark, isSpecial: true),
              _numpadButton('BACK', isDark, isSpecial: true, icon: Icons.backspace_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numpadButton(
    String label,
    bool isDark, {
    bool isSpecial = false,
    IconData? icon,
    Color? color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Material(
          color: isSpecial
              ? (isDark ? AppColors.darkCardElevated : Colors.white)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(14),
          elevation: isDark ? 0 : 1,
          child: InkWell(
            onTap: () => _onNumpadPress(label),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon, size: 20, color: color ?? (isDark ? Colors.white70 : Colors.black87))
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: isSpecial && label == '000' ? 14 : 18,
                        fontWeight: FontWeight.bold,
                        color: color ?? (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
