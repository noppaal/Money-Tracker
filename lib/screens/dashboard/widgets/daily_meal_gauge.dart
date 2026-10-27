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
    const baseline = AppConstants.defaultDailyMealTarget;
    final ratio = (dailyAllowance / baseline).clamp(0.0, 1.5);

    Color statusColor;
    String statusTitle;
    String statusMessage;
    IconData statusIcon;

    if (remainingFoodBudget <= 0) {
      statusColor = AppColors.danger;
      statusTitle = 'Habis';
      statusMessage = 'Anggaran makan bulan ini sudah habis. Perlu hemat ekstra!';
      statusIcon = Icons.warning_amber_rounded;
    } else if (dailyAllowance >= baseline) {
      statusColor = const Color(0xFF10B981);
      statusTitle = 'Aman & Fleksibel';
      statusMessage = 'Jatah makan hari ini melimpah! Nikmati harimu 🍛';
      statusIcon = Icons.sentiment_very_satisfied_rounded;
    } else if (dailyAllowance >= 35000) {
      statusColor = const Color(0xFFF59E0B);
      statusTitle = 'Terkendali';
      statusMessage = 'Jaga porsi pengeluaran agar cukup sampai akhir bulan 🍜';
      statusIcon = Icons.sentiment_satisfied_rounded;
    } else {
      statusColor = const Color(0xFFF97316);
      statusTitle = 'Hemat Ekstra';
      statusMessage = 'Jatah makan harian menipis. Prioritaskan menu hemat 🥣';
      statusIcon = Icons.sentiment_neutral_rounded;
    }

    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: statusColor.withOpacity(0.25),
          width: 1.2,
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
                        color: statusColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: statusColor,
                        size: 18,
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
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
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
                    border: Border.all(color: statusColor.withOpacity(0.35)),
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Center Dynamic Gauge Visual & Numbers
            Row(
              children: [
                // Animated Circular Arc Gauge
                SizedBox(
                  width: 90,
                  height: 90,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('gauge_${ratio}_$dailyAllowance'),
                    tween: Tween<double>(begin: 0.0, end: (ratio / 1.5).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedProgress, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(90, 90),
                            painter: _MealGaugePainter(
                              progress: animatedProgress,
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
                                size: 22,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(animatedProgress * 150).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 18),

                // Numerical Breakdown with smooth tween
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
                      const SizedBox(height: 3),
                      TweenAnimationBuilder<double>(
                        key: ValueKey('daily_meal_$dailyAllowance'),
                        tween: Tween<double>(begin: 0.0, end: dailyAllowance),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${CurrencyFormatter.format(value)} / hari',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          );
                        },
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withOpacity(0.18),
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
                        color: isDark ? Colors.white70 : Colors.black87,
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

  const _MealGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = 0.75 * pi;
    const sweepAngle = 1.5 * pi;

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

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activeSweep = sweepAngle * progress;

    if (activeSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MealGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
