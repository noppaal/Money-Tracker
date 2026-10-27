import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/finance_provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/summary_card.dart';
import 'widgets/daily_meal_gauge.dart';
import 'widgets/budget_envelope_card.dart';
import 'widgets/wallet_selector_sheet.dart';
import 'widgets/add_wallet_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final Function(String categoryId)? onSelectCategory;

  const DashboardScreen({
    super.key,
    this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MoneyTracker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Catatan Keuangan Pribadi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFFDE68A) : AppColors.darkSurface,
            ),
            tooltip: themeProvider.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: () => finance.loadData(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: finance.isLoading && finance.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : finance.errorMessage != null && finance.categories.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          finance.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => finance.loadData(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => finance.loadData(),
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      // 0. Active Wallet Selector Header
                      _buildWalletSelector(context, finance, isDark),
                      const SizedBox(height: 14),

                      // 1. Summary Card (Total Anggaran, Pengeluaran, Sisa)
                      const SummaryCard(),
                      const SizedBox(height: 16),

                      // 2. Dynamic Daily Meal Gauge
                      const DailyMealGauge(),
                      const SizedBox(height: 24),

                      // 3. Section Title: Pos Anggaran (Envelopes)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Pos Anggaran',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${finance.categories.length} Pos',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.formatCompact(finance.totalBudget),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 4. Budget Envelopes List
                      if (finance.categories.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: const Text('Belum ada pos anggaran. Buka Pengaturan untuk atur.'),
                        )
                      else
                        ...finance.categories.map(
                          (cat) => BudgetEnvelopeCard(
                            category: cat,
                            onTap: () {
                              if (onSelectCategory != null) {
                                onSelectCategory!(cat.id);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWalletSelector(
    BuildContext context,
    FinanceProvider finance,
    bool isDark,
  ) {
    final wallet = finance.selectedWallet;
    final isAll = finance.selectedWalletId == 'all';
    final walletColor = isAll ? AppColors.primary : (wallet?.color ?? AppColors.primary);
    final walletIcon = isAll
        ? Icons.account_balance_wallet_rounded
        : (wallet?.iconData ?? Icons.wallet_rounded);
    final walletName = isAll ? 'Semua Dompet' : (wallet?.name ?? 'Dompet Utama');
    final balance = finance.totalWalletBalance;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: walletColor.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            WalletSelectorSheet.show(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: walletColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: walletColor.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    walletIcon,
                    color: walletColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'DOMPET AKTIF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: walletColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: walletColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        walletName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Saldo Dompet',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(balance),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: balance < 0 ? AppColors.danger : walletColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  tooltip: 'Tambah Dompet',
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => AddWalletDialog.show(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
