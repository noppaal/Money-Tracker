import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/finance_provider.dart';

class DailyMealGauge extends StatelessWidget {
  const DailyMealGauge({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final food = finance.foodCategory;
    final dailyAllowance = finance.dailyMealAllowance;
    final daysRemaining = finance.remainingDaysInMonth;
    final remainingFoodBudget = food?.remainingAmount ?? 0.0;
    final allocatedFoodBudget = food?.allocatedAmount ?? AppConstants.defaultDailyMealTarget * 30;

    // Calculate status and health ratio
    // Target baseline is ~Rp60.000
    const baseline = AppConstants.defaultDailyMealTarget;
    final ratio = (dailyAllowance / baseline).clamp(0.0, 1.5);

    Color statusColor;
    String statusTitle;
    String statusMessage;
    IconData statusIcon;

    if (remainingFoodBudget <= 0) {
      statusColor = AppColors.danger;
      statusTitle = 'Overbudget Makan!';
      statusMessage = 'Anggaran makan bulan ini sudah habis. Perlu hemat ekstra!';
      statusIcon = Icons.warning_amber_rounded;
    } else if (dailyAllowance >= baseline) {
      statusColor = AppColors.success;
      statusTitle = 'Budget Aman & Fleksibel';
      statusMessage = 'Kamu bisa menikmati makan enak hari ini! 🍛';
      statusIcon = Icons.sentiment_very_satisfied_rounded;
    } else if (dailyAllowance >= 35000) {
      statusColor = AppColors.warning;
      statusTitle = 'Cukup & Terkendali';
      statusMessage = 'Jaga porsi pengeluaran agar cukup sampai akhir bulan 🍜';
      statusIcon = Icons.sentiment_satisfied_rounded;
    } else {
      statusColor = const Color(0xFFF97316); // Orange
      statusTitle = 'Perlu Berhemat';
      statusMessage = 'Jatah makan harian menipis. Prioritaskan masak sendiri 🥣';
      statusIcon = Icons.sentiment_neutral_rounded;
    }

    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Radar Makan Harian',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sisa $daysRemaining hari bulan ini',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Days Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        statusTitle,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Center Dynamic Gauge Visual & Numbers
            Row(
              children: [
                // Custom Circular Arc Gauge
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(90, 90),
                        painter: _MealGaugePainter(
                          progress: (ratio / 1.5).clamp(0.0, 1.0),
                          activeColor: statusColor,
                          backgroundColor: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lunch_dining_rounded,
                            color: statusColor,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(ratio * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),

                // Numerical Breakdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jatah Makan Hari Ini',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${CurrencyFormatter.format(dailyAllowance)} / hari',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sisa budget: ${CurrencyFormatter.format(remainingFoodBudget)} dari ${CurrencyFormatter.format(allocatedFoodBudget)}',
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
            const SizedBox(height: 16),

            // Contextual Tip Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: statusColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, color: statusColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealGaugePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color backgroundColor;

  _MealGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background Arc (from 135 deg to 405 deg = 270 deg total)
    const startAngle = 135 * (pi / 180);
    const sweepAngle = 270 * (pi / 180);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active Progress Arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final currentSweep = sweepAngle * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MealGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
