import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/finance_provider.dart';
import 'widgets/summary_card.dart';
import 'widgets/daily_meal_gauge.dart';
import 'widgets/budget_envelope_card.dart';

class DashboardScreen extends StatelessWidget {
  final Function(String categoryId)? onSelectCategory;

  const DashboardScreen({
    super.key,
    this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MoneyTracker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Catatan Keuangan Pribadi',
                  style: TextStyle(
                    fontSize: 11,
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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: () => finance.loadData(),
          ),
        ],
      ),
      body: finance.isLoading && finance.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => finance.loadData(),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
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
                        'Total 4.5jt',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
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
}
