import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_item.dart';
import '../../providers/finance_provider.dart';
import 'widgets/transaction_tile.dart';
import 'widgets/edit_transaction_dialog.dart';
import '../dashboard/widgets/wallet_selector_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to group transactions by calendar date (yyyy-MM-dd)
  Map<String, List<TransactionItem>> _groupTransactions(List<TransactionItem> list) {
    final Map<String, List<TransactionItem>> groups = {};
    for (final tx in list) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedType = finance.selectedTypeFilter;

    final categories = selectedType == 'income'
        ? finance.incomeCategories
        : (selectedType == 'expense' ? finance.expenseCategories : finance.categories);

    final filtered = finance.filteredTransactions;
    final grouped = _groupTransactions(filtered);
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final selectedWallet = finance.selectedWallet;
    final isAllWallets = finance.selectedWalletId == 'all';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            InkWell(
              onTap: () => WalletSelectorSheet.show(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAllWallets
                          ? Icons.account_balance_wallet_rounded
                          : (selectedWallet?.iconData ?? Icons.wallet_rounded),
                      size: 13,
                      color: isAllWallets
                          ? AppColors.primary
                          : (selectedWallet?.color ?? AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAllWallets
                          ? 'Semua Dompet'
                          : (selectedWallet?.name ?? 'Dompet Utama'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Month Selector
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: finance.selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                finance.changeMonth(picked);
              }
            },
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: Text(
              DateFormatter.formatMonthYear(finance.selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Cash Flow Mini Summary Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pemasukan',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+${CurrencyFormatter.format(finance.totalIncome)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengeluaran',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '-${CurrencyFormatter.format(finance.totalSpent)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEF4444),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Arus Kas',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${finance.netCashFlow >= 0 ? '+' : ''}${CurrencyFormatter.format(finance.netCashFlow)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: finance.netCashFlow >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari catatan atau nominal...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          finance.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => finance.setSearchQuery(val),
            ),
          ),

          // Type Filter Tabs: [ Semua ] [ 🔴 Pengeluaran ] [ 🟢 Pemasukan ]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Semua'),
                    selected: selectedType == 'all',
                    onSelected: (_) => finance.setTypeFilter('all'),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedType == 'all' ? FontWeight.bold : FontWeight.normal,
                      color: selectedType == 'all' ? AppColors.primary : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_outward_rounded, size: 14, color: AppColors.danger),
                        SizedBox(width: 4),
                        Text('Pengeluaran'),
                      ],
                    ),
                    selected: selectedType == 'expense',
                    onSelected: (_) => finance.setTypeFilter('expense'),
                    selectedColor: AppColors.danger.withOpacity(0.18),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedType == 'expense' ? FontWeight.bold : FontWeight.normal,
                      color: selectedType == 'expense' ? AppColors.danger : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text('Pemasukan'),
                      ],
                    ),
                    selected: selectedType == 'income',
                    onSelected: (_) => finance.setTypeFilter('income'),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.18),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedType == 'income' ? FontWeight.bold : FontWeight.normal,
                      color: selectedType == 'income' ? const Color(0xFF10B981) : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua Kategori'),
                  selected: finance.selectedCategoryFilter == null,
                  onSelected: (_) => finance.setCategoryFilter(null),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                ...categories.map((cat) {
                  final isSelected = finance.selectedCategoryFilter == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      avatar: Icon(cat.iconData, size: 16, color: cat.color),
                      label: Text(cat.name),
                      selected: isSelected,
                      selectedColor: cat.color.withOpacity(0.2),
                      checkmarkColor: cat.color,
                      onSelected: (val) {
                        finance.setCategoryFilter(val ? cat.id : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 12),

          // Transaction List Grouped by Date
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tekan tombol (+) di bawah untuk mencatat transaksi',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final key = sortedKeys[index];
                      final items = grouped[key]!;
                      final dateObj = items.first.date;
                      final dailyExpense = items
                          .where((i) => i.isExpense)
                          .fold(0.0, (sum, item) => sum + item.amount);
                      final dailyIncome = items
                          .where((i) => i.isIncome)
                          .fold(0.0, (sum, item) => sum + item.amount);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group Header (Date & Daily Stats)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormatter.formatGroupHeader(dateObj),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (dailyIncome > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '+${CurrencyFormatter.format(dailyIncome)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    if (dailyIncome > 0 && dailyExpense > 0) const SizedBox(width: 4),
                                    if (dailyExpense > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger.withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '-${CurrencyFormatter.format(dailyExpense)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // List of transactions for this day
                          ...items.map(
                            (tx) => TransactionTile(
                              transaction: tx,
                              onTap: () => EditTransactionDialog.show(context, tx),
                              onDelete: () => finance.deleteTransaction(tx.id),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
