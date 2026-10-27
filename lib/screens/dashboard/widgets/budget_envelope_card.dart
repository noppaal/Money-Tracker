import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/budget_category.dart';

class BudgetEnvelopeCard extends StatelessWidget {
  final BudgetCategory category;
  final VoidCallback? onTap;

  const BudgetEnvelopeCard({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = category.usageRatio;
    final isOverbudget = category.isOverbudget;
    final remaining = category.remainingAmount;

    // Progress color rules:
    // Green -> Yellow if > 75% -> Red if overbudget (> 100%)
    final statusColor = AppColors.getBudgetProgressColor(ratio);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOverbudget
              ? AppColors.danger.withOpacity(0.45)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isOverbudget ? 1.5 : 1.0,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: category.color.withOpacity(0.1),
          highlightColor: category.color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top Row: Icon, Name, and Status Badge
                Row(
                  children: [
                    // Category Icon with glow
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: category.color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        category.iconData,
                        color: category.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name & Remaining text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isOverbudget
                                ? 'Overbudget: ${CurrencyFormatter.format(remaining.abs())}'
                                : 'Sisa: ${CurrencyFormatter.format(remaining)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOverbudget
                                  ? AppColors.danger
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Percentage Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${(ratio * 100).toInt()}%',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Smooth Tween-Animated Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey('cat_${category.id}_${ratio.clamp(0.0, 1.0)}'),
                      tween: Tween<double>(begin: 0.0, end: ratio.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: animValue,
                          child: Container(
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Bottom Numerical Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terpakai ${CurrencyFormatter.format(category.spentAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      'Pagu ${CurrencyFormatter.format(category.allocatedAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
