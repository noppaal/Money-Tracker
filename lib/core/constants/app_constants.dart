class AppConstants {
  static const String appName = 'MoneyTracker';
  static const String dbName = 'money_tracker.db';
  static const int dbVersion = 1;

  // Total Baseline Budget: Rp4.500.000
  static const double defaultTotalBudget = 4500000.0;

  // Default Daily Meal Target Baseline (~Rp60.000/hari)
  static const double defaultDailyMealTarget = 60000.0;

  // Quick Amount Presets for Quick Add Sheet
  static const List<double> quickPresets = [
    15000.0,
    25000.0,
    50000.0,
    100000.0,
  ];

  // Quick Note Suggestions
  static const List<String> quickNotes = [
    'Makan Siang',
    'Kopi & Cemilan',
    'Bensin',
    'Token Listrik',
    'Indomaret / Alfamart',
    'Laundry Kiloan',
    'Paket Data',
  ];
}
