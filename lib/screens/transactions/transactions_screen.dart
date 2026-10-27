import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_item.dart';
import '../../providers/finance_provider.dart';
import 'widgets/transaction_tile.dart';
import 'widgets/edit_transaction_dialog.dart';

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
    final categories = finance.categories;
    final filtered = finance.filteredTransactions;
    final grouped = _groupTransactions(filtered);
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
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
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua'),
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

          const Divider(height: 16),

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
                          'Tekan tombol (+) di bawah untuk mencatat pengeluaran',
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
                      final dailyTotal = items.fold(0.0, (sum, item) => sum + item.amount);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group Header (Date & Daily Total)
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.darkCardElevated : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Total: ${CurrencyFormatter.format(dailyTotal)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
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
