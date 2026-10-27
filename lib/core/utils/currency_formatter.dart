import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _numberOnly = NumberFormat('#,###', 'id_ID');

  /// Formats double amount to 'Rp1.800.000'
  static String format(double amount, {bool withPrefix = true, bool withSpace = false}) {
    final prefix = withPrefix ? (withSpace ? 'Rp ' : 'Rp') : '';
    final formattedNumber = _numberOnly.format(amount.round().abs());
    final sign = amount < 0 ? '-' : '';
    return '$sign$prefix$formattedNumber';
  }

  /// Compact format: 'Rp1,8jt', 'Rp60rb'
  static String formatCompact(double amount) {
    if (amount.abs() >= 1000000) {
      final val = amount / 1000000;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1).replaceAll('.', ',')}jt';
    } else if (amount.abs() >= 1000) {
      final val = amount / 1000;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 0)}rb';
    }
    return format(amount);
  }

  /// Parses string like '1800000' or '1.800.000' to double
  static double parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0.0;
    return double.tryParse(cleaned) ?? 0.0;
  }
}
